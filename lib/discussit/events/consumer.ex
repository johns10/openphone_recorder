defmodule Discussit.Events.Consumer do
  use GenServer
  alias Discussit.Events.Openphone.Projector
  alias Discussit.Events
  require Logger

  @default_state %{subscribed: [], count: 0}

  def start_link(opts) do
    name = Map.get(opts, :name, __MODULE__)
    state = Map.merge(@default_state, opts)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def set_count(count) do
    GenServer.call(__MODULE__, {:set_count, count})
  end

  def set_subscriber(pid) do
    GenServer.call(__MODULE__, {:set_subscriber, pid})
  end

  def start() do
    GenServer.cast(__MODULE__, {:start})
  end

  @impl true
  def init(state) do
    {:ok, state, {:continue, :next}}
  end

  @impl true
  def handle_call({:set_count, count}, _from, state) do
    {:reply, count, Map.put(state, :count, count)}
  end

  def handle_call({:set_subscriber, pid}, _from, %{subscribed: subscribed} = state) do
    state = Map.put(state, :subscribed, [pid | subscribed])
    {:reply, subscribed, state}
  end

  @impl true
  def handle_cast({:start}, state) do
    {:noreply, state, {:continue, :next}}
  end

  @impl true
  def handle_continue(:next, %{count: 0} = state), do: {:noreply, state}

  def handle_continue(:next, state) do
    result = maybe_consume(state)
    send_result(state, result)

    state
    |> handle_count(result)
    |> maybe_continue(result)
  end

  defp maybe_consume(%{count: count}) when count != 0, do: consume()

  defp consume() do
    Events.list_unprocessed_events()
    |> case do
      [event] ->
        Logger.info("Processing event #{event.id} with no additional events in the queue")
        consume_event(event)

      [event | _] ->
        Logger.info("Processing event #{event.id} with additional events in the queue.")
        consume_event(event)

      [] ->
        Logger.info("No events in database.")
        {:error, :empty}
    end
  end

  defp consume_event(event) do
    event.payload
    |> Events.cast_event()
    |> Projector.apply(event.account_id)
    |> case do
      {:ok, _} ->
        Discussit.Events.update_event(event, %{processed: true})

      {:error, error} ->
        Discussit.Events.update_event(event, %{skipped: true})
        Logger.error(inspect(error))
        {:error, error}
    end
  end

  defp send_result(state, result) do
    result
    |> case do
      {:ok, event} ->
        Enum.each(state.subscribed, &send(&1, {:consumed, event}))

      _ ->
        nil
    end
  end

  defp handle_count(%{count: count} = state, result) do
    case result do
      {:ok, _} ->
        count =
          case count do
            :inf -> :inf
            count when is_integer(count) -> count - 1
          end

        Map.put(state, :count, count)

      _ ->
        state
    end
  end

  defp maybe_continue(state, result) do
    result
    |> case do
      {:ok, _} ->
        {:noreply, state, {:continue, :next}}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, state, {:continue, :next}}

      {:error, :empty} ->
        {:noreply, state}
    end
  end
end
