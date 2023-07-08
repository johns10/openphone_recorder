defmodule OpenphoneRecorder.Events.Consumer do
  use GenServer
  alias OpenphoneRecorder.Events.Openphone.Projector
  alias OpenphoneRecorder.Events
  require Logger

  @default_state %{timer: nil, delay: 60000, subscribed: [], count: 0}

  def start_link(opts) do
    name = Map.get(opts, :name, __MODULE__)
    state = Map.merge(@default_state, opts)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def set_count(count) do
    GenServer.call(__MODULE__, {:set_count, count})
  end

  def set_delay(delay) do
    GenServer.call(__MODULE__, {:set_delay, delay})
  end

  def set_subscriber(pid) do
    GenServer.call(__MODULE__, {:set_subscriber, pid})
  end

  @impl true
  def init(state) do
    {:ok, state, {:continue, :next}}
  end

  @impl true
  def handle_call({:set_count, count}, _from, %{timer: timer} = state) do
    Process.cancel_timer(timer)
    {:reply, count, Map.put(state, :count, count), {:continue, :next}}
  end

  def handle_call({:set_delay, delay}, _from, %{timer: timer} = state) do
    Process.cancel_timer(timer)
    {:reply, delay, Map.put(state, :delay, delay), {:continue, :schedule_next_run}}
  end

  def handle_call({:set_subscriber, pid}, _from, %{subscribed: subscribed} = state) do
    state = Map.put(state, :subscribed, [pid | subscribed])
    {:reply, subscribed, state}
  end

  @impl true
  def handle_info(:consume, state) do
    state
    |> case do
      %{count: count} = state when count in [0] ->
        {:noreply, state, {:continue, :schedule_next_run}}

      state ->
        state
        |> consume()
        |> after_consume(state)
    end
  end

  @impl true
  def handle_continue(:schedule_next_run, %{delay: delay} = state) do
    {:noreply, Map.put(state, :timer, Process.send_after(self(), :consume, delay))}
  end

  def handle_continue(:next, state) do
    state
    |> consume()
    |> after_consume(state)
  end

  defp consume(%{count: 0}), do: {:error, :done}

  defp consume(%{count: count} = state) when count > 0 do
    Events.list_unprocessed_events()
    |> case do
      [event] ->
        Logger.info("Processing event with no additional events in the queue")
        consume_event(event)

      [event | _] ->
        Logger.info(
          "Processing event #{event.id} with additional events in the queue. Will process #{state.count} additional events."
        )

        consume_event(event)

      [] ->
        Logger.info("No events in database, scheduling next run. #{state.count} left to process.")
        {:error, :empty}
    end
  end

  defp consume_event(event) do
    event.payload
    |> Events.cast_event()
    |> Projector.apply()
    |> case do
      {:ok, _} ->
        OpenphoneRecorder.Events.update_event(event, %{processed: true})

      {:error, error} ->
        Logger.error(inspect(error))
        {:error, error}
    end
  end

  defp after_consume(result, %{count: count} = state) do
    result
    |> case do
      {:ok, event} ->
        Enum.each(state.subscribed, &send(&1, {:consumed, event}))

        count =
          case count do
            :inf -> :inf
            count when is_integer(count) -> count - 1
          end

        {:noreply, Map.put(state, :count, count), {:continue, :next}}

      {:error, _changeset} ->
        {:noreply, state, {:continue, :schedule_next_run}}
    end
  end
end
