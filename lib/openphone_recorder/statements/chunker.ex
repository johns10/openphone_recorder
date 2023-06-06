defmodule OpenphoneRecorder.Statements.Chunker do
  @behaviour OpenphoneRecorder.Statements.Chunker.Behaviour
  alias OpenphoneRecorder.Tokens

  @eighteen_hours 18 * 60 * 60

  @impl true
  def prompt_fun(chunk_style), do: impl(chunk_style).prompt_fun()

  def chunk(statements, opts) do
    [statements]
    |> Enum.map(&(acc(&1) |> temporal_chunks(opts)))
    |> Enum.reduce([], fn list, acc -> acc ++ list end)
    |> Enum.map(&(acc(&1) |> token_count_chunks(opts)))
    |> Enum.reduce([], fn list, acc -> acc ++ list end)
  end

  def acc(statements), do: %{queue: statements, current: [], done: []}

  def temporal_chunks(%{queue: queue, done: done}, _) when queue == [], do: done

  def temporal_chunks(%{queue: [head, next | _]} = acc, opts) do
    time_gap = Keyword.get(opts, :time_gap, @eighteen_hours)

    case DateTime.diff(head.occurred_at, next.occurred_at) do
      time when time <= time_gap ->
        acc
        |> add_to_current()
        |> shift_queue(1)

      time when time > time_gap ->
        acc
        |> complete_current()
        |> shift_queue(1)
    end
    |> temporal_chunks(opts)
  end

  def temporal_chunks(acc, opts) do
    acc
    |> complete_current()
    |> shift_queue(1)
    |> temporal_chunks(opts)
  end

  def token_count_chunks(%{queue: queue, current: current} = acc, _)
      when queue == [] and length(current) > 0 do
    acc
    |> complete_current()
    |> Map.get(:done)
  end

  def token_count_chunks(%{done: done, queue: queue}, _) when queue == [], do: done

  def token_count_chunks(%{queue: [head, next | _], current: current} = acc, opts) do
    current_count = Tokens.count(current)
    next_count = Tokens.count(next)
    head_count = Tokens.count(head)
    Tokens.max_text_count(opts)

    (current_count + head_count + next_count > Tokens.max_text_count(opts))
    |> case do
      false ->
        acc
        |> add_to_current()
        |> shift_queue(1)

      true ->
        acc
        |> complete_current()
        |> put_current([next])
        |> shift_queue(2)
    end
    |> token_count_chunks(opts)
  end

  def token_count_chunks(%{queue: [head | _], current: current} = acc, opts) do
    current_count = Tokens.count(current)
    head_count = Tokens.count(head)
    Tokens.max_text_count(opts)

    (current_count + head_count > Tokens.max_text_count(opts))
    |> case do
      false ->
        acc
        |> add_to_current()
        |> shift_queue(1)

      true ->
        acc
        |> complete_current()
        |> shift_queue(1)
    end
    |> token_count_chunks(opts)
  end

  def shift_queue(%{queue: [_ | tail]} = acc, 1), do: Map.put(acc, :queue, tail)
  def shift_queue(%{queue: [_, _ | tail]} = acc, 2), do: Map.put(acc, :queue, tail)
  def shift_queue(acc, _), do: acc

  defp complete_current(%{done: done, queue: [head | _], current: current} = acc),
    do:
      acc
      |> Map.put(:done, [[head | current] | done])
      |> Map.put(:current, [])

  defp complete_current(%{done: done, queue: [], current: current} = acc),
    do:
      acc
      |> Map.put(:done, [current | done])
      |> Map.put(:current, [])

  defp put_current(acc, current), do: Map.put(acc, :current, current)

  def add_to_current(%{current: current, queue: [head | _]} = acc),
    do: Map.put(acc, :current, [head | current])

  defp impl(:temporal), do: OpenphoneRecorder.Statements.Chunker.Temporal
end
