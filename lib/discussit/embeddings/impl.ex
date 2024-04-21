defmodule Discussit.Embeddings.Impl do
  @model_id "BAAI/bge-large-en-v1.5"
  alias Discussit.Embeddings.Embedding
  alias Discussit.Tokens
  alias Discussit.Embeddings
  alias Discussit.Statements
  alias Discussit.Usages
  alias Discussit.Statements.Statement
  require Logger

  def embed_statements(limit \\ 500) do
    Logger.info("#{__MODULE__}.embed_statements")

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
    |> Flow.map(&filter_unprocessable/1)
    |> Flow.map(&filter_all_stopwords/1)
    |> Flow.map(&create_embedding/1)
    |> Flow.map(&put_vector/1)
    |> Enum.map(& &1)
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
    repo = {:hf, "BAAI/bge-large-en-v1.5"}
    {:ok, model_info} = Bumblebee.load_model(repo, architecture: :base)
    {:ok, tokenizer} = Bumblebee.load_tokenizer(repo)
    serving = Bumblebee.Text.TextEmbedding.text_embedding(model_info, tokenizer)
    %{embedding: embedding} = Nx.Serving.run(serving, text)
    list = Nx.to_list(embedding)
    vector = Pgvector.new(list)
    {:ok, vector}
  end
end
