defmodule Discussit.TopicAnalyzer do
  alias Discussit.Accounts.Account
  alias Discussit.Statements
  alias Discussit.Topics
  alias Discussit.TopicAnalyzer.Server
  require Logger

  def init(%Account{} = account) do
    bucket = Application.get_env(:discussit, :bucket)
    object = object_path(account)
    query_opts = [filters: [embedded: true, account_id: account.id], preloads: [:embedding]]

    model_attrs = %{
      model_path: local_path(account),
      openai_api_key: Application.get_env(:openai, :api_key)
    }

    with false <- model_exists?(account),
         :ok <- create_model(bucket, object),
         statements <- Statements.list_statements(query_opts),
         {:ok, %{topic_assignments: topic_assignments, topics: model_topics}} <-
           Server.init_model(statements, model_attrs),
         # TODO Implement model backup hered
         topics <- insert_new_topics(model_topics, account.id),
         statements <- update_statement_topics(statements, topic_assignments, topics) do
      {:ok, statements}
    else
      true -> {:error, "analyzer model already exists"}
    end
  end

  def train(%Account{} = account) do
    query_opts = [filters: [embedded: true, account_id: account.id], preloads: [:embedding]]

    with true <- model_exists?(account),
         statements <- Statements.list_statements(query_opts),
         {:ok, statement_topics} <- provider().train_model(statements, local_path(account)),
         # TODO Implement model backup here
         {:ok, model_topics} <- provider().get_topics(local_path(account)),
         topics <- insert_new_topics(model_topics, account.id),
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
    topic_map = Enum.reduce(topics, %{}, fn topic, acc -> Map.put(acc, topic.model_id, topic) end)

    Enum.zip(statements, statement_topics)
    |> Enum.map(fn
      {statement, %{topic: -1}} ->
        statement

      {statement, %{topic: topic_id}} ->
        topic_id = topic_map |> Map.get(topic_id) |> Map.get(:id)

        case Statements.update_statement(statement, %{topic_id: topic_id}) do
          {:ok, statement} ->
            statement

          {:error, changeset} ->
            Logger.error(
              "#{__MODULE__}.update_statement_topics failed due to #{inspect(changeset)}"
            )
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
      |> Enum.filter(&(&1.model_id != -1))
      |> Enum.map(fn attrs ->
        attrs
        |> Map.put(:account_id, account_id)
        |> Topics.create_topic()
        |> case do
          {:ok, topic} ->
            topic

          {:error, changeset} ->
            Logger.error("#{__MODULE__}.insert_new_topics failed because #{inspect(changeset)}")
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

  def delete_model(account) do
    bucket = Application.get_env(:discussit, :bucket)
    object = object_path(account)

    ExAws.S3.delete_object(bucket, object)
    |> ExAws.request()
    |> case do
      {:ok, %{status_code: 204}} -> :ok
      _ -> :error
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
