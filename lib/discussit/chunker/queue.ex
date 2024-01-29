defmodule Discussit.Chunker.Queue do
  def acc(items), do: %{queue: items, current: [], done: []}

  def shift_queue(%{queue: [_ | tail]} = acc, 1), do: Map.put(acc, :queue, tail)
  def shift_queue(%{queue: [_, _ | tail]} = acc, 2), do: Map.put(acc, :queue, tail)
  def shift_queue(acc, _), do: acc

  def complete_current(%{done: done, queue: [head | _], current: current} = acc),
    do:
      acc
      |> Map.put(:done, [Enum.reverse([head | current]) | done])
      |> Map.put(:current, [])

  def complete_current(%{done: done, queue: [], current: current} = acc),
    do:
      acc
      |> Map.put(:done, [Enum.reverse(current) | done])
      |> Map.put(:current, [])

  def put_current(acc, current), do: Map.put(acc, :current, current)

  def add_to_current(%{current: current, queue: [head | _]} = acc),
    do: Map.put(acc, :current, [head | current])
end
