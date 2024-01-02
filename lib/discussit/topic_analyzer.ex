defmodule Discussit.TopicAnalyzer do
  alias Discussit.Models.Model
  alias Discussit.Accounts.Account
  alias Discussit.{Statements, Topics, Models}
  alias Discussit.Topics.Topic
  alias Discussit.Topics.Keywords
  require Logger

  @default_opts [statement_count: 1_000_000]

  def init(%Account{id: account_id} = account, opts \\ @default_opts) do
    statements_count = Keyword.get(opts, :statement_count)
    model_id = Keyword.get(opts, :model_id, nil)
    impl = Application.get_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)

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

    last_topics =
      case Models.get_latest_model!(account_id) do
        %Model{id: id} -> Topics.list_topics(filters: [model_id: id])
        nil -> []
      end

    with {:ok, path} = Briefly.create(directory: true),
         {:ok, model} <- Models.create_model(%{id: model_id, account_id: account_id}),
         {:ok, pid} <-
           impl.start_link(%{model_id: model.id, account_id: account_id, parent: self()}),
         statements <- Statements.list_statements(query_opts),
         :ok <- impl.init_model(pid, statements, path) do
      receive do
        {:done, topics} ->
          {:ok, _} = put_object(model_path(model), "#{path}/model.zip")
          Keywords.match(last_topics, topics)
          {:ok, %{statements: statements, topics: topics, model: model}}
      after
        360_000 -> Logger.error("Initialization receive block failed")
      end
    end
  end

  def train(%Account{} = account) do
    query_opts = [filters: [embedded: true, account_id: account.id], preloads: [:embedding]]

    with {:ok, path} = Briefly.create(),
         {:ok, model} <- Models.create_model(%{account_id: account.id}),
         statements <- Statements.list_statements(query_opts),
         {:ok, statement_topics} <- provider().train_model(statements, path),
         # TODO Implement model backup here
         {:ok, model_topics} <- provider().get_topics(path),
         topics <- insert_new_topics(model_topics, model, account.id),
         statements <- update_statement_topics(statements, statement_topics, topics) do
      {:ok, statements}
    else
      false -> {:error, "analyzer model missing"}
    end
  end

  defp update_statement_topics(statements, statement_topics, topics) do
    topic_map =
      Enum.reduce(topics, %{}, fn topic, acc -> Map.put(acc, topic.topic_model_id, topic) end)

    Enum.zip(statements, statement_topics)
    |> Enum.map(fn
      {statement, attrs} ->
        %{trained_topic_id: topic_id, representative: rep} = cast_statement_topic_attrs(attrs)
        trained_topic_id = topic_map |> Map.get(topic_id) |> Map.get(:id)
        attrs = %{trained_topic_id: trained_topic_id, representative: rep}

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

      model_topic ->
        model_topic
        |> cast_model_topic()
        |> Map.put(:account_id, account_id)
        |> Map.put(:model_id, model.id)
        |> Topics.create_topic()
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
        |> Map.put(:model_id, model_id)
        |> Topics.create_topic()

      %Topic{} = topic ->
        attrs =
          attrs
          |> Map.put(:model_id, model_id)
          |> Map.put(:topic_model_id, -1)

        Topics.update_topic(topic, attrs)
    end
    |> case do
      {:ok, topic} -> topic
      {:error, c} -> Logger.error("#{__MODULE__}.insert_new_topics #{inspect(c)}")
    end
  end

  def model_path(%Model{id: id}), do: "/topic_analyzer_models/#{id}-model"
  def merge_path(%Model{id: id}), do: "/topic_analyzer_models/#{id}-merge"

  defp put_object(object, path) do
    bucket = Application.get_env(:discussit, :bucket)

    ExAws.S3.put_object(bucket, object, File.read!(path))
    |> ExAws.request()
  end

  def provider(),
    do: Application.get_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)

  defp cast_model_topic(%{'topic_model_id' => topic_model_id, 'keywords' => keywords}),
    do: %{topic_model_id: topic_model_id, keywords: keywords}

  defp cast_statement_topic_attrs(%{'trained_topic_id' => t_id, 'representative' => r}),
    do: %{trained_topic_id: t_id, representative: r}
end
