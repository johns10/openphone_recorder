defmodule Discussit.Chunker.Weekly do
  @behaviour Discussit.Chunker.Behaviour
  alias Discussit.Chunker.Queue
  alias Discussit.DateSupport

  @impl true
  def chunk_items(queue, opts \\ [])

  def chunk_items(%{queue: queue, done: done}, _) when queue == [],
    do: done

  def chunk_items(%{queue: [head, next | _]} = acc, opts) do
    case split?(head, next, opts) do
      true ->
        acc
        |> Queue.add_to_current()
        |> Queue.shift_queue(1)

      false ->
        acc
        |> Queue.complete_current()
        |> Queue.shift_queue(1)
    end
    |> chunk_items(opts)
  end

  def chunk_items(acc, opts) do
    acc
    |> Queue.complete_current()
    |> Queue.shift_queue(1)
    |> chunk_items(opts)
  end

  def split?(head, next, opts) do
    head_date = DateSupport.range_day(head.summary_interval, opts)
    next_date = DateSupport.range_day(next.summary_interval, opts)

    DateSupport.week(head_date) == DateSupport.week(next_date)
  end
end
