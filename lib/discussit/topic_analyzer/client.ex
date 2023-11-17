defmodule Discussit.TopicAnalyzer.Client do
  use GenServer
  alias Discussit.TopicAnalyzer.WebsocketClient
  require Logger
  defstruct websocket_pid: nil, owner: nil

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(%{owner: owner}), do: {:ok, %__MODULE__{owner: owner}}

  def connect(port), do: GenServer.call(__MODULE__, {:connect, port})
  def disconnect(), do: GenServer.call(__MODULE__, :disconnect)

  @impl true

  def handle_call({:connect, _port}, _from, %{websocket_pid: pid} = state) when is_pid(pid),
    do: {:reply, :ok, state}

  def handle_call({:connect, port}, _from, %{websocket_pid: nil} = state) do
    args = Map.put(state, :port, port)
    {:ok, websocket_pid} = WebsocketClient.start_link(args)
    {:reply, :ok, %{state | websocket_pid: websocket_pid}}
  end

  def handle_call(:disconnect, _from, %{websocket_pid: nil} = state), do: {:reply, :ok, state}

  def handle_call(:disconnect, _from, %{websocket_pid: websocket_pid} = state)
      when is_pid(websocket_pid) do
    Process.exit(websocket_pid, :disconnect_websocket)
    {:reply, :ok, %{state | websocket_pid: nil}}
  end

  @impl true
  def handle_info({:EXIT, pid, :normal}, %{websocket_pid: websocket_pid, owner: owner} = state) do
    Logger.error(
      "#{__MODULE__} received an exit signal from pid #{inspect(pid)} (alive: #{Process.alive?(pid)}), client pid is #{inspect(websocket_pid)}, owner pid is #{inspect(owner)}"
    )

    case Process.alive?(pid) || owner == pid do
      false -> {:noreply, state}
      true -> {:stop, :shutdown, state}
    end
  end

  def handle_info({:EXIT, _pid, :disconnect_websocket}, state), do: {:noreply, state}

  defdelegate init_model(statements, model_attrs), to: WebsocketClient
  defdelegate get_topics(args), to: WebsocketClient
end

defmodule Discussit.TopicAnalyzer.WebsocketClient do
  use Retry
  use WebSockex
  require Logger

  def start_link(%{owner: _, port: _} = state) do
    Process.flag(:trap_exit, true)
    connect(state)
  end

  defp connect(%{port: port} = state) do
    retry_while with: linear_backoff(500, 1) |> expiry(20_000) do
      address = "127.0.0.1"

      "ws://#{address}:#{port}/data"
      |> WebSockex.start_link(__MODULE__, state, name: __MODULE__)
      |> case do
        {:ok, pid} -> {:halt, {:ok, pid}}
        {:error, %{code: 403}} -> {:cont, {:error, :econnrefused}}
        {:error, %{original: :econnrefused}} -> {:cont, {:error, :econnrefused}}
        {:error, {:already_started, pid}} -> {:halt, {:ok, pid}}
      end
    end
  end

  def handle_frame({:text, message}, state) do
    with {:ok, data} <- Jason.decode(message, keys: :atoms) do
      handle_message(data, state)
    end
  end

  def handle_frame(other, state) do
    Logger.info("#{__MODULE__} received unhandle frame #{inspect(other)}")
    {:ok, state}
  end

  def handle_message(%{message_type: "statement_received"}, state), do: {:ok, state}

  def handle_message(%{message_type: "model_initialized"} = msg, %{owner: pid} = state) do
    %{payload: %{topic_assignments: _, topics: _} = payload} = msg
    Process.send(pid, {:ok, payload}, [])
    {:ok, state}
  end

  def handle_message(%{message_type: "topics_received"} = msg, %{owner: pid} = state) do
    %{payload: %{topics: topics}} = msg
    Process.send(pid, {:topics_received, topics}, [])
    {:ok, state}
  end

  def handle_disconnect(_conn, _state) do
    Logger.warn("Websocket Disconnected!")
  end

  def send_statement(statement) do
    msg =
      %{message_type: "statement_data", payload: statement}
      |> Jason.encode!()

    WebSockex.send_frame(__MODULE__, {:binary, msg})
  end

  def init_model(statements, args) do
    msg =
      %{message_type: "init_model", payload: args}
      |> Jason.encode!()

    :ok = Enum.each(statements, &send_statement/1)

    WebSockex.send_frame(__MODULE__, {:binary, msg})
  end

  def get_topics(args) do
    msg =
      %{message_type: "get_topics", payload: args}
      |> Jason.encode!()

    WebSockex.send_frame(__MODULE__, {:binary, msg})
  end
end
