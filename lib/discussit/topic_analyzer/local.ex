defmodule Discussit.TopicAnalyzer.Local do
  # @behaviour Discussit.TopicAnalyzer.Behaviour
  alias Discussit.Topics
  alias Discussit.Topics.Topic
  alias Discussit.Statements
  require Logger
  use GenServer

  def start_link(%{model_id: _} = default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(state) do
    {:ok, python_pid} = start()
    {:ok, Map.merge(state, %{python_pid: python_pid, topics: []})}
  end

  def start() do
    Logger.info("#{__MODULE__} starting a python instance")
    path = [:code.priv_dir(:discussit), "python"] |> Path.join()

    {:ok, pid} =
      :python.start([
        {:python_path, to_charlist(path)},
        {:python, 'python3'}
      ])

    impl = Application.get_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)
    :ok = :python.call(pid, :topics_port, :import_impl, [impl])
    :ok = :python.call(pid, :topics_port, :register_handler, [self()])
    {:ok, pid}
  end

  def init_model(pid, statements, model_path),
    do: GenServer.cast(pid, {:init_model, statements, model_path})

  def stop(pid) do
    :python.stop(pid)
  end

  ############################### SERVER ###############################

  @impl true
  def handle_info({:create_topic, topic_attrs}, state), do: create_topic(topic_attrs, state)

  def handle_info({:assign_topic, statement_attrs}, state),
    do: update_statement_topic(statement_attrs, state)

  def handle_info(:done, %{parent: parent, topics: topics} = state) do
    send(parent, {:done, topics})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:init_model, statements, model_path}, %{python_pid: pid} = state) do
    Enum.map(statements, fn %{embedding: %{vector: vector} = embedding} = statement ->
      statement = %{statement | embedding: %{embedding | vector: Pgvector.to_list(vector)}}
      :python.call(pid, :topics_port, :save_item, [statement])
    end)

    :python.cast(pid, {:init_model, model_path})

    {:noreply, state}
    |> IO.inspect(label: :end_of_handle_cast)
  end

  ############################### IMPL ###############################

  defp create_topic(
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

  defp create_topic(
         topic_attrs,
         %{model_id: model_id, account_id: account_id, topics: topics} = state
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

  defp cast_topic_attrs(%{'topic_model_id' => topic_model_id, 'keywords' => keywords}),
    do: %{topic_model_id: topic_model_id, keywords: keywords}

  defp update_statement_topic(attrs, %{topics: topics} = state) do
    %{id: id, trained_topic_id: topic_id, representative: rep} = cast_statement_attrs(attrs)
    trained_topic_id = Enum.find(topics, &(&1.topic_model_id == topic_id)) |> Map.get(:id)
    attrs = %{trained_topic_id: trained_topic_id, representative: rep}

    Statements.get_statement!(id)
    |> Statements.update_statement(attrs)
    |> case do
      {:ok, statement} -> statement
      {:error, c} -> Logger.error("#{__MODULE__}.update_statement_topics #{inspect(c)}")
    end

    {:noreply, state}
  end

  defp cast_statement_attrs(%{'id' => id, 'trained_topic_id' => t_id, 'representative' => r}),
    do: %{id: to_string(id), trained_topic_id: t_id, representative: r}
end
