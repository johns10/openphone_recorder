defmodule Discussit.TopicAnalyzer.Server do
  defstruct account_id: nil,
            model: nil,
            from: nil,
            model_path: nil,
            job: nil,
            python_pid: nil,
            topics: [],
            statements: []

  alias Discussit.TopicAnalyzer.Impl
  use GenServer
  require Logger

  @impl true
  def init(state) do
    {:ok, Map.merge(state, %__MODULE__{})}
  end

  @impl true
  def handle_call({:initialize, account, opts}, from, state) do
    {:ok, %{model: model, model_path: model_path, python_pid: python_pid}} =
      Impl.start_initialization(account, opts)

    {:noreply,
     %{
       state
       | model: model,
         model_path: model_path,
         account_id: account.id,
         from: from,
         python_pid: python_pid,
         job: :initialize
     }}
  end

  @impl true
  def handle_call({:train, account, opts}, from, state) do
    {:ok, %{model: model, model_path: model_path, python_pid: python_pid}} =
      Impl.start_initialization(account, opts)

    {:noreply,
     %{
       state
       | model: model,
         model_path: model_path,
         account_id: account.id,
         from: from,
         python_pid: python_pid,
         job: :train
     }}
  end

  @impl true
  def handle_info({:create_topic, attrs}, state), do: Impl.create_topic(attrs, state)

  def handle_info({:assign_topic, attrs}, state) do
    case Impl.update_statement(attrs, state) do
      {:ok, statement} ->
        {:noreply, %{state | statements: [statement | state.statements]}}

      {:error, changeset} ->
        Logger.error("#{__MODULE__} update_statement #{inspect(changeset)}")
        {:noreply, state}
    end
  end

  def handle_info(:done, %{from: from, job: :initialize} = state) do
    {:ok, model} = Impl.finish_initialization(state)
    state = %{state | model: model}
    GenServer.reply(from, {:ok, Map.take(state, [:topics, :model, :statements])})
    {:noreply, state}
  end

  def handle_info(:done, %{from: from, job: :train} = state) do
    {:ok, model} = Impl.finish_training(state)
    state = %{state | model: model}
    GenServer.reply(from, {:ok, Map.take(state, [:topics, :model, :statements])})
    {:noreply, state}
  end
end
