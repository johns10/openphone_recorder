defmodule Discussit.TopicAnalyzer.Server do
  defstruct server_pid: nil, client_pid: nil, timer_ref: nil, state: :not_started
  use GenServer
  alias Discussit.TopicAnalyzer.Client
  @idle_time 10_000

  def start_link(opts) do
    name = Map.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: name)
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  def start(), do: GenServer.cast(__MODULE__, :start)
  def stop(), do: GenServer.cast(__MODULE__, :stop)

  def ensure_started(), do: GenServer.call(__MODULE__, :ensure_started, 10_000)
  def get_topics(args), do: GenServer.call(__MODULE__, {:get_topics, args})

  def init_model(statements, args),
    do: GenServer.call(__MODULE__, {:init_model, statements, args}, 30_000)

  @impl true
  def handle_cast(:start, state), do: {:noreply, start(state)}
  def handle_cast(:stop, state), do: {:noreply, stop(state)}

  @impl true
  def handle_call(:ensure_started, _from, state), do: {:reply, :ok, start(state)}

  def handle_call({:init_model, statements, args}, _from, state) do
    :ok = Client.init_model(statements, args)

    receive do
      {:ok, response} when is_map(response) -> {:reply, {:ok, response}, state}
    end
  end

  def handle_call({:get_topics, args}, _from, state) do
    :ok = Client.get_topics(args)

    receive do
      {:topics_received, topics} when is_map(topics) -> {:reply, {:ok, topics}, state}
    end
  end

  def start(%{state: :started, server_pid: server_pid} = state) do
    case(Process.alive?(server_pid)) do
      false -> start(state)
      true -> refresh(state)
    end
  end

  def start(state) do
    with {:ok, server_pid} <- provider().start(),
         {:ok, client_pid} <- Client.start_link(%{owner: self()}) do
      timer_ref = Process.send_after(self(), :stop, @idle_time)

      %{
        state
        | server_pid: server_pid,
          state: :started,
          timer_ref: timer_ref,
          client_pid: client_pid
      }
    end
  end

  def stop(%{server_pid: server_pid}) do
    :python.stop(server_pid)
  end

  def refresh(%{timer_ref: timer_ref} = state) do
    Process.cancel_timer(timer_ref)
    timer_ref = Process.send_after(self(), :stop, @idle_time)

    {:noreply, %{state | timer_ref: timer_ref}}
  end

  def provider(), do: Discussit.TopicAnalyzer.provider()
end
