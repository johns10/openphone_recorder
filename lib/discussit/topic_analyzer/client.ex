defmodule Discussit.TopicAnalyzer.Client do
  use Retry
  use WebSockex

  def start_link(%{owner: _} = state) do
    connect(state)
  end

  defp connect(state) do
    retry_while with: linear_backoff(500, 1) |> expiry(20_000) do
      address = "localhost"
      port = ":5000"

      "ws://#{address}#{port}/data"
      |> WebSockex.start_link(__MODULE__, state, name: __MODULE__)
      |> case do
        {:ok, pid} -> {:halt, {:ok, pid}}
        {:error, _} -> {:cont, {:error, :econnrefused}}
      end
    end
  end

  def handle_frame({:text, message}, state) do
    with {:ok, data} <- Jason.decode(message, keys: :atoms) do
      handle_message(data, state)
    end
  end

  def handle_frame(other, state) do
    IO.inspect(other)
    {:ok, state}
  end

  def handle_message(%{message_type: "statement_received"}, state), do: {:ok, state}

  def handle_message(%{message_type: "model_initialized"} = msg, %{owner: pid} = state) do
    IO.puts("sending message back to #{inspect(pid)}")
    %{payload: %{topic_assignments: _, topics: _} = payload} = msg
    Process.send(pid, {:ok, payload}, [])
    {:ok, state}
  end

  def handle_message(%{message_type: "topics_received"} = msg, %{owner: pid} = state) do
    %{payload: %{topics: topics}} = msg
    Process.send(pid, {:topics_received, topics}, [])
    {:ok, state}
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
