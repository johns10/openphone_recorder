defmodule Discussit.Embeddings.Impl do
  @model_id "BAAI/bge-large-en-v1.5"
  alias Discussit.Embeddings.Embedding
  alias Discussit.Tokens
  alias Discussit.Embeddings
  alias Discussit.HTTP
  alias Discussit.Statements
  alias Discussit.Usages
  alias Discussit.Statements.Statement
  require Logger

  def start_model() do
    case get_embedding("") do
      {:ok, %Pgvector{}} ->
        Logger.info("Model started")
        :ok

      {:ok, %{status_code: 200}} ->
        Logger.info("Model started")
        :ok

      {:error, error} ->
        Logger.info("Model not started because #{inspect(error)}")
        :error
    end
  end

  def embed_statements(limit \\ 500) do
    Stream.resource(
      fn -> 0 end,
      fn acc ->
        case Statements.list_statements(
               limit: limit,
               offset: acc,
               filters: [embedded: false, all_stopwords: false, embedding_enabled: true],
               preloads: [conversation: :account]
             ) do
          [] -> {:halt, acc}
          [_ | _] = result -> {[result], acc + limit}
        end
      end,
      fn acc -> acc end
    )
    |> Flow.from_enumerable(max_demand: 1)
    |> Flow.flat_map(& &1)
    |> Flow.map(&%{status: :ok, source: &1})
    |> Flow.map(&check_model/1)
    |> Flow.map(&filter_unprocessable/1)
    |> Flow.map(&filter_all_stopwords/1)
    |> Flow.map(&create_embedding/1)
    |> Flow.map(&put_vector/1)
    |> Enum.map(& &1)
  end

  defp check_model(state) do
    case Discussit.Embeddings.ModelStatus.get() do
      :started -> state
      :not_started -> Map.put(state, :status, :model_not_started)
    end
  end

  defp filter_unprocessable(%{status: :ok, source: %Statement{content: nil}} = state),
    do: handle_unprocessable(state)

  defp filter_unprocessable(%{status: :ok, source: %Statement{content: content}} = state) do
    with {:integer, :error} <- {:integer, Integer.parse(content)} do
      state
    else
      {:integer, {_int, _rem}} ->
        handle_unprocessable(state)
    end
  end

  defp filter_unprocessable(state), do: state

  defp handle_unprocessable(%{source: statement} = state) do
    {:ok, statement} = Statements.update_statement(statement, %{unprocessable: true})

    state
    |> Map.put(:status, :skipped)
    |> Map.put(:status_detail, "Integer")
    |> Map.put(:source, statement)
  end

  defp filter_all_stopwords(%{status: :ok, source: %Statement{} = statement} = state) do
    %{content: content} = statement

    with true <- Tokens.all_stopwords?(content),
         {:ok, statement} <- Statements.update_statement(statement, %{all_stopwords: true}) do
      state
      |> Map.put(:status, :skipped)
      |> Map.put(:status_detail, "All stopwords")
      |> Map.put(:source, statement)
    else
      false ->
        {:ok, statement} = Statements.update_statement(statement, %{all_stopwords: false})
        Map.put(state, :source, statement)

      {:error, changeset} ->
        state
        |> Map.put(:status, :error)
        |> Map.put(:status_detail, changeset)
    end
  end

  defp filter_all_stopwords(state), do: state

  defp create_embedding(%{status: :ok, source: %Statement{} = statement} = state) do
    %{id: statement_id} = statement

    %{status: :created, model: String.to_atom(@model_id), statement_id: statement_id}
    |> Embeddings.create_embedding()
    |> case do
      {:ok, embedding} ->
        Map.put(state, :embedding, embedding)

      {:error, changeset} ->
        state
        |> Map.put(:status, :error)
        |> Map.put(:status_detail, changeset)
    end
  end

  defp create_embedding(state), do: state

  defp put_vector(
         %{status: :ok, embedding: %Embedding{} = embedding, source: %Statement{} = statement} =
           state
       ) do
    %{content: content, conversation: %{account_id: account_id}} = statement

    usage_attrs =
      Usages.calculate_total(%{
        meta: %{tokens: Tokens.count(content)},
        model: "BAAI/bge-large-en-v1.5",
        product: :embedding,
        provider: :discussit,
        account_id: account_id
      })

    with {:ok, embedding} <- Embeddings.update_embedding(embedding, %{status: :running}),
         {:ok, %Pgvector{} = vector} <- get_embedding(content),
         {:ok, _usage} <- Usages.create_usage(usage_attrs),
         {:ok, embedding} <-
           Embeddings.update_embedding(embedding, %{vector: vector, status: :complete}) do
      Map.put(state, :embedding, embedding)
    else
      {:error, :not_started} ->
        Embeddings.delete_embedding(embedding)
        Map.put(state, :status, :error)

      {:error, error} ->
        Logger.error(error)
        Embeddings.delete_embedding(embedding)
        Map.put(state, :status, :error)
    end
  end

  defp put_vector(state), do: state

  def get_embedding(text) do
    api_token = System.get_env("HUGGINGFACE_API_KEY")
    url = "https://api-inference.huggingface.co/models/#{@model_id}"

    headers = [{"Authorization", "Bearer #{api_token}"}]

    with {:ok, %{status_code: 200, body: body}} <- HTTP.post(url, text, headers),
         {:ok, list} <- Jason.decode(body),
         vector <- Pgvector.new(list) do
      {:ok, vector}
    else
      {:ok, %{status_code: 503, body: json}} ->
        with {:ok, %{"error" => error, "estimated_time" => eta}} <- Jason.decode(json) do
          Discussit.Embeddings.ModelStatus.set(:not_started)
          Logger.warning("#{error}, eta: #{eta}")
          {:error, :not_started}
        end

      {:ok, %{status_code: status_code, body: json}} ->
        with {:ok, %{"error" => error}} <- Jason.decode(json) do
          Logger.warning(
            "#{__MODULE__}.get_embedding failed with status code #{status_code}: #{error}"
          )

          {:error, error}
        end
    end
  end
end
