defmodule OpenphoneRecorder.Statements.Chunker do
  @behaviour OpenphoneRecorder.Statements.Chunker.Behaviour

  alias OpenphoneRecorder.Tokens
  alias OpenphoneRecorder.Chunker.Queue

  @impl true
  def prompt(chunker, text, opts), do: impl(chunker).prompt(text, opts)

  @impl true
  def prompt_count(chunker, opts), do: impl(chunker).prompt_count(opts)

  def acc(statements), do: %{queue: statements, current: [], done: []}

  def chunk(statements, opts) do
    [statements]
    |> Enum.map(&(Queue.acc(&1) |> temporal_chunks(opts)))
    |> Enum.reduce([], fn list, acc -> acc ++ list end)
    |> Enum.map(&(Queue.acc(&1) |> token_count_chunks(opts)))
    |> Enum.reduce([], fn list, acc -> acc ++ list end)
  end

  def temporal_chunks(%{queue: queue, done: done}, _) when queue == [],
    do: done

  def temporal_chunks(%{queue: [head, next | _]} = acc, opts) do
    case NaiveDateTime.to_date(head.occurred_at) == NaiveDateTime.to_date(next.occurred_at) do
      true ->
        acc
        |> Queue.add_to_current()
        |> Queue.shift_queue(1)

      false ->
        acc
        |> Queue.complete_current()
        |> Queue.shift_queue(1)
    end
    |> temporal_chunks(opts)
  end

  def temporal_chunks(acc, opts) do
    acc
    |> Queue.complete_current()
    |> Queue.shift_queue(1)
    |> temporal_chunks(opts)
  end

  def token_count_chunks(%{queue: queue, current: current} = acc, _)
      when queue == [] and length(current) > 0 do
    acc
    |> Queue.complete_current()
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
        |> Queue.add_to_current()
        |> Queue.shift_queue(1)

      true ->
        acc
        |> Queue.complete_current()
        |> Queue.put_current([next])
        |> Queue.shift_queue(2)
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
        |> Queue.add_to_current()
        |> Queue.shift_queue(1)

      true ->
        acc
        |> Queue.complete_current()
        |> Queue.shift_queue(1)
    end
    |> token_count_chunks(opts)
  end

  defp impl(:temporal), do: OpenphoneRecorder.Statements.Chunker.Temporal
  defp impl(:test), do: OpenphoneRecorder.Statements.Chunker.Test
end
