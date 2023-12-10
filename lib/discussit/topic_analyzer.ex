defmodule Discussit.TopicAnalyzer do
  alias Discussit.Accounts.Account
  alias Discussit.{Statements, Topics, Models}
  alias Discussit.Topics.Topic
  alias Discussit.TopicAnalyzer.Server
  require Logger

  def init(%Account{id: account_id} = account, statements_count \\ 1_000_000) do
    query_opts = [
      filters: [
        embedded: true,
        trained: false,
        all_stopwords: false,
        unprocessable: false,
        account_id: account.id
      ],
      preloads: [:embedding, :labelled_topic],
      order_by: [labelled_topic_id: :desc],
      limit: statements_count
    ]

    with false <- model_exists?(account),
         {:ok, model} <- Models.create_model(%{account_id: account_id}),
         {:ok, urls} <- Models.get_model_urls(model.id, :put),
         statements <- Statements.list_statements(query_opts),
         {:ok, %{topic_assignments: topic_assignments, topics: model_topics}} <-
           Server.init_model(statements, urls |> Map.put(:id, model.id)),
         topics <- insert_new_topics(model_topics, model, account.id),
         statements <- update_statement_topics(statements, topic_assignments, topics) do
      {:ok, statements}
    else
      true -> {:error, "analyzer model already exists"}
    end
  end

  def train(%Account{} = account) do
    query_opts = [filters: [embedded: true, account_id: account.id], preloads: [:embedding]]
    model_path = local_path(account)

    with true <- model_exists?(account),
         {:ok, model} <- Models.create_model(%{account_id: account.id}),
         statements <- Statements.list_statements(query_opts),
         {:ok, statement_topics} <- provider().train_model(statements, model_path),
         # TODO Implement model backup here
         {:ok, model_topics} <- provider().get_topics(model_path),
         topics <- insert_new_topics(model_topics, model, account.id),
         statements <- update_statement_topics(statements, statement_topics, topics) do
      {:ok, statements}
    else
      false -> {:error, "analyzer model missing"}
    end
  end

  def regenerate_labels(account) do
    provider().regenerate_labels(local_path(account))
  end

  defp update_statement_topics(statements, statement_topics, topics) do
    topic_map =
      Enum.reduce(topics, %{}, fn topic, acc -> Map.put(acc, topic.topic_model_id, topic) end)

    Enum.zip(statements, statement_topics)
    |> Enum.map(fn
      {statement, %{trained_topic_id: topic_id, representative: representative}} ->
        trained_topic_id = topic_map |> Map.get(topic_id) |> Map.get(:id)
        attrs = %{trained_topic_id: trained_topic_id, representative: representative}

        case Statements.update_statement(statement, attrs) do
          {:ok, statement} -> statement
          {:error, c} -> Logger.error("#{__MODULE__}.update_statement_topics #{inspect(c)}")
        end
    end)
  end

  defp insert_new_topics(model_topics, model, account_id) do
    model_topics
    |> Enum.map(fn
      %{topic_model_id: -1} = model_topic ->
        ensure_outliers_topic(model_topic, model, account_id)

      %{topic_model_id: topic_model_id} = model_topic ->
        attrs = Map.put(model_topic, :account_id, account_id)
        attrs = if(topic_model_id == -1, do: Map.put(attrs, :title, "Outliers"), else: attrs)

        case Topics.get_topic_by(%{topic_model_id: topic_model_id, account_id: account_id}) do
          nil -> Topics.create_topic(attrs)
          %Topic{} = topic -> Topics.update_topic(topic, attrs)
        end
        |> case do
          {:ok, topic} -> topic
          {:error, c} -> Logger.error("#{__MODULE__}.insert_new_topics #{inspect(c)}")
        end
    end)
  end

  defp ensure_outliers_topic(attrs, %{id: model_id}, account_id) do
    case Topics.get_topic_by(%{topic_model_id: -1, account_id: account_id}) do
      nil ->
        attrs
        |> Map.put(:title, "Outliers")
        |> Map.put(:description, "These are outliers, which couldn't be assigned to any topic.")
        |> Map.put(:topic_model_id, -1)
        |> Map.put(:account_id, account_id)
        |> Topics.create_topic()

      %Topic{} = topic ->
        attrs = Map.put(attrs, :model_id, model_id)
        Topics.update_topic(topic, attrs)
    end
    |> case do
      {:ok, topic} -> topic
      {:error, c} -> Logger.error("#{__MODULE__}.insert_new_topics #{inspect(c)}")
    end
  end

  defp create_model(bucket, object) do
    ExAws.S3.put_object(bucket, object, "")
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      e -> e
    end
  end

  def model_exists?(account) do
    bucket = Application.get_env(:discussit, :bucket)
    object = object_path(account)

    ExAws.S3.head_object(bucket, object)
    |> ExAws.request()
    |> case do
      {:error, {:http_error, 404, %{status_code: 404}}} -> false
      {:ok, _} -> true
      _ -> {:error, "uncaught error in #{__MODULE__}.check_object"}
    end
  end

  def object_path(%Account{id: id}), do: "/topic_analyzer_models/#{id}"

  def local_path(%Account{id: id}),
    do: "#{Application.get_env(:discussit, :model_path)}/#{id}.model"

  def provider(),
    do: Application.get_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)
end
