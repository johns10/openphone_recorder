defmodule Discussit.TopicAnalyzer do
  alias Discussit.Accounts.Account
  alias Discussit.Statements
  alias Discussit.Topics

  def init(%Account{} = account) do
    bucket = Application.get_env(:discussit, :bucket)
    object = model_path(account)

    with false <- check_object?(bucket, object),
         :ok <- create_model(bucket, object),
         statements <- Statements.list_statements(filters: [account_id: account.id]),
         content = Enum.map(statements, & &1.content),
         {:ok, statement_topics} <- provider().init_model(content, account.id),
         # TODO Implement model backup here
         {:ok, model_topics} <- provider().get_topics(account.id),
         topics <- insert_new_topics(model_topics, account.id),
         statements <- update_statement_topics(statements, statement_topics, topics) do
      {:ok, statements}
    else
      true -> {:error, "analyzer model already exists"}
    end
  end

  def train(%Account{} = account) do
    bucket = Application.get_env(:discussit, :bucket)
    object = model_path(account)
    query_opts = [filters: [account_id: account.id, nil_topic_id: true]]

    with true <- check_object?(bucket, object),
         statements <- Statements.list_statements(query_opts),
         content = Enum.map(statements, & &1.content),
         {:ok, statement_topics} <- provider().train_model(content, account.id),
         # TODO Implement model backup here
         {:ok, model_topics} <- provider().get_topics(account.id),
         topics <- insert_new_topics(model_topics, account.id),
         statements <- update_statement_topics(statements, statement_topics, topics) do
      {:ok, statements}
    else
      false -> {:error, "analyzer model missing"}
    end
  end

  defp update_statement_topics(statements, statement_topics, topics) do
    topic_map = Enum.reduce(topics, %{}, fn topic, acc -> Map.put(acc, topic.model_id, topic) end)

    Enum.zip(statements, statement_topics)
    |> Enum.map(fn {statement, statement_topic} ->
      topic_id = topic_map |> Map.get(statement_topic) |> Map.get(:id)

      case Statements.update_statement(statement, %{topic_id: topic_id}) do
        {:ok, statement} -> statement
        {:error, changeset} -> IO.inspect(changeset)
      end
    end)
  end

  defp insert_new_topics(model_topics, account_id) do
    topics = Topics.list_topics(filters: [account_id: account_id])

    new_model_topics =
      Enum.reduce(topics, model_topics, fn topic, acc ->
        Map.delete(acc, topic.model_id)
      end)

    new_topics =
      new_model_topics
      |> Enum.map(fn {model_id, name} ->
        %{model_id: model_id, model_title: to_string(name), account_id: account_id}
        |> Topics.create_topic()
        |> case do
          {:ok, topic} -> topic
          {:error, changeset} -> IO.inspect(changeset)
        end
      end)

    Enum.uniq(new_topics ++ topics)
  end

  defp create_model(bucket, object) do
    ExAws.S3.put_object(bucket, object, "")
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      e -> e
    end
  end

  defp check_object?(bucket, object) do
    ExAws.S3.head_object(bucket, object)
    |> ExAws.request()
    |> case do
      {:error, {:http_error, 404, %{status_code: 404}}} -> false
      {:ok, _} -> true
      _ -> {:error, "uncaught error in #{__MODULE__}.check_object"}
    end
  end

  def model_path(%Account{id: id}), do: "/topic_analyzer_models/#{id}"

  defp provider(),
    do: Application.get_env(:discussit, :topic_analysis_provider, Discussit.TopicAnalyzer.Local)
end
