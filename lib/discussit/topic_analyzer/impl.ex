defmodule Discussit.TopicAnalyzer.Impl do
  alias Discussit.Topics
  alias Discussit.Topics.Topic
  alias Discussit.Topics.Keywords
  alias Discussit.Models
  alias Discussit.Models.Model
  alias Discussit.Statements
  require Logger

  def start_initialization(%{id: account_id} = account, opts) do
    statements_count = Keyword.get(opts, :statement_count)
    model_id = Keyword.get(opts, :model_id, nil)

    query_opts = [
      filters: [
        embedded: true,
        trained: false,
        all_stopwords: false,
        unprocessable: false,
        account_id: account.id
      ],
      preloads: [:embedding, :labelled_topic],
      order_by: [inserted_at: :desc],
      limit: statements_count
    ]

    with {:ok, model_path} = Briefly.create(directory: true),
         {:ok, pid} <- start_python(),
         statements <- Statements.list_statements(query_opts),
         ids <- Enum.map(statements, & &1.id),
         {:ok, model} <-
           Models.create_model(%{id: model_id, account_id: account_id, trained_ids: ids}) do
      Enum.map(statements, fn %{embedding: %{vector: vector} = embedding} = statement ->
        statement = %{statement | embedding: %{embedding | vector: Pgvector.to_list(vector)}}
        :python.call(pid, :topics_port, :save_item, [statement])
      end)

      :python.cast(pid, {:init_model, model_path})
      {:ok, %{model: model, model_path: model_path, python_pid: pid}}
    end
  end

  def merge_topics(model_id, topic_ids, _opts) do
    bucket = Application.get_env(:discussit, :bucket)

    %{trained_ids: ids} = model = Models.get_model!(model_id)

    statements =
      Statements.list_statements(
        filters: [ids: ids],
        order_by: [inserted_at: :desc],
        preloads: [:embedding, :labelled_topic]
      )

    object = Models.merge_path(model)

    {:ok, pid} = start_python()

    {:ok, archive_path} = Briefly.create(extname: ".zip")
    {:ok, model_path} = Briefly.create(directory: true)
    {:ok, %{body: binary}} = ExAws.S3.get_object(bucket, object) |> ExAws.request()
    :ok = File.write(archive_path, binary)

    {:ok, files} = :zip.unzip(to_charlist(archive_path), [:memory])

    Enum.each(files, fn {filename, binary} ->
      base_name = Path.basename(filename)
      new_filename = Path.join(model_path, base_name)
      :ok = File.touch!(new_filename)
      :ok = File.write!(new_filename, binary)
    end)

    Enum.map(statements, fn %{embedding: %{vector: vector} = embedding} = statement ->
      statement = %{statement | embedding: %{embedding | vector: Pgvector.to_list(vector)}}
      :python.call(pid, :topics_port, :save_item, [statement])
    end)

    :python.call(pid, :topics_port, :merge_topics, [model_path, topic_ids])
  end

  def finish_initialization(%{
        model: model,
        topics: topics,
        account_id: account_id,
        model_path: model_path,
        python_pid: pid
      }) do
    merge_object = Models.merge_path(model)
    model_object = Models.model_path(model)
    attrs = %{merge_object: merge_object, model_object: model_object}

    with {:ok, archive_path} = Briefly.create(extname: ".zip"),
         {:ok, archive_path} <-
           :zip.create(to_charlist(archive_path), list_model_files(model_path)),
         {:ok, _} <- put_object(merge_object, archive_path),
         {:ok, _} <- put_object(model_object, archive_path),
         {:ok, model} <- Models.update_model(model, attrs),
         :ok <- :python.stop(pid) do
      candidates = Enum.filter(topics, &(&1.hierarchy? == false))
      match_topics(account_id, candidates)

      {:ok, model}
    end
  end

  def finish_training(%{
        model: model,
        topics: topics,
        account_id: account_id,
        model_path: model_path,
        python_pid: python_pid
      }) do
    [_ | old_models] =
      Models.list_models(filters: [account_id: account_id], order_by: [inserted_at: :desc])

    {:ok, archive_path} = Briefly.create(extname: ".zip")

    model_dirs =
      Enum.map(old_models, fn %{model_object: object} ->
        bucket = Application.get_env(:discussit, :bucket)

        with {:ok, %{body: binary}} <- ExAws.S3.get_object(bucket, object) |> ExAws.request(),
             :ok <- File.write(archive_path, binary),
             {:ok, [model_dir]} <- :zip.unzip(to_charlist(archive_path)) do
          model_dir
        end
      end)

    merge_object = Models.merge_path(model)
    model_object = Models.model_path(model)
    attrs = %{merge_object: merge_object, model_object: model_object}

    with :ok = :python.call(python_pid, :topics_port, :merge_models, [model_dirs, model_path]),
         {:ok, archive_path} <-
           :zip.create(to_charlist(archive_path), list_model_files(model_path)),
         {:ok, _} <- put_object(merge_object, archive_path),
         {:ok, _} <- put_object(model_object, archive_path),
         {:ok, model} <- Models.update_model(model, attrs) do
      match_topics(account_id, topics)
      {:ok, model}
    end
  end

  def create_topic(
        %{topic_model_id: -1} = attrs,
        %{model_id: model_id, account_id: account_id, topics: topics} = state
      ) do
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
      {:ok, topic} ->
        updated_topics = [topic | topics]
        {:noreply, %{state | topics: updated_topics}}

      {:error, c} ->
        Logger.error("#{__MODULE__}.ensure_outlier_topic #{inspect(c)}")
        {:noreply, state}
    end
  end

  def create_topic(
        topic_attrs,
        %{model: %{id: model_id}, account_id: account_id, topics: topics} = state
      ) do
    topic_attrs
    |> cast_topic_attrs()
    |> Map.put(:account_id, account_id)
    |> Map.put(:model_id, model_id)
    |> Topics.create_topic()
    |> case do
      {:ok, topic} ->
        updated_topics = [topic | topics]
        {:noreply, %{state | topics: updated_topics}}

      {:error, c} ->
        Logger.error("#{__MODULE__}.insert_new_topics #{inspect(c)}")
        {:noreply, state}
    end
  end

  def start_python() do
    Logger.info("#{__MODULE__} starting a python instance")
    path = [:code.priv_dir(:discussit), "python"] |> Path.join()

    {:ok, python_pid} =
      :python.start([
        {:python_path, to_charlist(path)},
        {:python, 'python3'}
      ])

    impl = Application.get_env(:discussit, :topic_analyzer_impl, Discussit.TopicAnalyzer.Local)
    :ok = :python.call(python_pid, :topics_port, :import_impl, [impl])
    :ok = :python.call(python_pid, :topics_port, :register_handler, [self()])

    {:ok, python_pid}
  end

  def update_statement(attrs, %{topics: topics}) do
    %{id: id, trained_topic_id: topic_id, representative: rep} = cast_statement_attrs(attrs)
    trained_topic_id = Enum.find(topics, &(&1.topic_model_id == topic_id)) |> Map.get(:id)
    attrs = %{trained_topic_id: trained_topic_id, representative: rep}

    Statements.get_statement!(id)
    |> Statements.update_statement(attrs)
  end

  def update_topic_hierarchy(attrs, %{topics: topics}) do
    %{topic_model_id: topic_model_id, parent_topic_model_id: parent_topic_model_id} =
      cast_hierarchy_attrs(attrs)

    parent_id = Enum.find(topics, &(&1.topic_model_id == parent_topic_model_id)) |> Map.get(:id)

    Enum.find(topics, &(&1.topic_model_id == topic_model_id))
    |> Topics.update_topic(%{parent_id: parent_id})
  end

  defp put_object(object, path) do
    bucket = Application.get_env(:discussit, :bucket)

    ExAws.S3.put_object(bucket, object, File.read!(path))
    |> ExAws.request()
  end

  defp get_object(object, path) do
    bucket = Application.get_env(:discussit, :bucket)

    ExAws.S3.get_object(bucket, object)
    |> ExAws.request()
  end

  defp cast_topic_attrs(%{
         'topic_model_id' => topic_model_id,
         'keywords' => keywords,
         :hierarchy? => hierarchy?
       }),
       do: %{topic_model_id: topic_model_id, keywords: keywords, hierarchy?: hierarchy?}

  defp cast_topic_attrs(attrs),
    do:
      %{}
      |> cast_field(attrs, 'model_title')
      |> cast_field(attrs, 'topic_model_id')
      |> cast_field(attrs, :hierarchy?)

  defp cast_statement_attrs(%{'id' => id, 'trained_topic_id' => t_id, 'representative' => r}),
    do: %{id: to_string(id), trained_topic_id: t_id, representative: r}

  defp cast_hierarchy_attrs(attrs) do
    %{}
    |> cast_field(attrs, 'parent_topic_model_id')
    |> cast_field(attrs, 'topic_model_id')
  end

  defp cast_field(result, attrs, name) when name in ['parent_topic_model_id', 'topic_model_id'] do
    case Map.has_key?(attrs, name) do
      true ->
        value =
          Map.get(attrs, name)
          |> to_string()
          |> String.to_integer()

        key = name |> to_string() |> String.to_atom()

        Map.put(result, key, value)

      false ->
        result
    end
  end

  defp cast_field(result, attrs, name) when name in ['model_title'] do
    case Map.has_key?(attrs, name) do
      true ->
        value =
          Map.get(attrs, name)
          |> to_string()

        key = name |> to_string() |> String.to_atom()

        Map.put(result, key, value)

      false ->
        result
    end
  end

  defp cast_field(result, attrs, name) when is_atom(name) do
    case Map.has_key?(attrs, name) do
      true -> Map.put(result, name, attrs[name])
      false -> result
    end
  end

  defp list_model_files(model_path) do
    File.ls!(model_path)
    |> Enum.map(&Path.join(model_path, &1))
    |> Enum.map(&to_charlist/1)
  end

  def match_topics(account_id, topics) do
    case Models.get_latest_model!(account_id) do
      %Model{id: id} -> Topics.list_topics(filters: [model_id: id, hierarchy?: false])
      nil -> []
    end
    |> Keywords.match(topics)
  end
end
