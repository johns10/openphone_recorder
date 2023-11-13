defmodule Discussit.TopicAnalyzer.Server do
  defstruct server_pid: nil, client_pid: nil, timer_ref: nil, status: :not_started, port: nil
  use GenServer
  require Logger
  @idle_time 30_000

  def start_link(opts) do
    name = Map.get(opts, :name, __MODULE__)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_) do
    {:ok, nil, {:continue, :start_processes}}
  end

  def stop_server(), do: GenServer.cast(__MODULE__, :stop_server)

  def ensure_stopped(), do: GenServer.call(__MODULE__, :ensure_stopped, 10_000)
  def ensure_server_started(), do: GenServer.call(__MODULE__, :ensure_server_started, 10_000)
  def ensure_server_stopped(), do: GenServer.call(__MODULE__, :ensure_server_stopped, 10_000)

  def init_model(statements, args),
    do: GenServer.call(__MODULE__, {:init_model, statements, args}, 30_000)

  @impl true
  def handle_continue(:start_processes, _state) do
    :timer.sleep(1)
    {:ok, server_pid} = server_provider().start()
    {:ok, client_pid} = client_provider().start_link(%{owner: self()})

    {:noreply, %__MODULE__{client_pid: client_pid, server_pid: server_pid}}
  end

  @impl true
  def handle_cast(:start, state), do: {:noreply, start_server(state)}
  def handle_cast(:stop, state), do: {:noreply, stop_processes(state)}
  def handle_cast(:stop_server, state), do: {:noreply, stop_server(state)}

  @impl true
  def handle_call(:ensure_stopped, _from, state), do: {:reply, :ok, stop_processes(state)}
  def handle_call(:ensure_server_started, _from, state), do: {:reply, :ok, start_server(state)}
  def handle_call(:ensure_server_stopped, _from, state), do: {:reply, :ok, stop_server(state)}

  def handle_call({:init_model, statements, args}, _from, state) do
    state = clear_timeout(state)
    :ok = client_provider().init_model(statements, args)

    receive do
      {:ok, response} when is_map(response) -> {:reply, {:ok, response}, start_timeout(state)}
    end
  end

  def handle_call({:get_topics, args}, _from, state) do
    state = clear_timeout(state)
    :ok = client_provider().get_topics(args)

    receive do
      {:topics_received, topics} when is_map(topics) ->
        {:reply, {:ok, topics}, start_timeout(state)}
    end
  end

  @impl true
  def handle_info(:stop_server, state), do: {:noreply, stop_server(state)}

  @impl true
  def terminate(reason, state) do
    Logger.info("#{__MODULE__} terminating because #{inspect(reason)}")
    stop_processes(state)
  end

  def start_server(%{server_pid: pid, status: :not_started} = state) when is_pid(pid) do
    with {:ok, %{port: port, status: status}} <- server_provider().start_server(pid),
         :ok <- client_provider().connect(port) do
      %{state | status: status, port: port}
    end
  end

  def start_server(state), do: state

  def start_timeout(%{timer_ref: nil} = state),
    do: %{state | timer_ref: Process.send_after(self(), :stop_server, @idle_time)}

  def start_timeout(%{timer_ref: timer_ref} = state) when is_reference(timer_ref) do
    Process.cancel_timer(timer_ref)
    %{state | timer_ref: timer_ref}
  end

  def clear_timeout(%{timer_ref: nil} = state), do: state

  def clear_timeout(%{timer_ref: timer_ref} = state) when is_reference(timer_ref) do
    Process.cancel_timer(timer_ref)
    %{state | timer_ref: nil}
  end

  def server_provider(),
    do: Application.get_env(:discussit, :topic_analysis_server, Discussit.TopicAnalyzer.Local)

  def client_provider(),
    do: Application.get_env(:discussit, :topic_analysis_client, Discussit.TopicAnalyzer.Client)

  def stop_server(%{client_pid: _client_pid, server_pid: server_pid} = state) do
    Logger.info("stopping #{__MODULE__} server normally")
    client_provider().disconnect()
    {:ok, server_pid} = server_provider().stop_server(server_pid)
    %{state | status: :not_started, client_pid: nil, server_pid: server_pid}
  end

  def stop_processes(%{server_pid: server_pid, client_pid: client_pid} = state) do
    if is_pid(client_pid), do: Process.exit(client_pid, :ok)

    if is_pid(server_pid) do
      server_provider().stop_server(server_pid)
      server_provider().stop(server_pid)
    end

    state
  end
end
