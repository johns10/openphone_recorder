defmodule OpenphoneRecorder.Chunker.TokenCount do
  @behaviour OpenphoneRecorder.Chunker.Behaviour
  alias OpenphoneRecorder.Chunker.Queue
  alias OpenphoneRecorder.Tokens

  def chunk_items(queue, opts \\ [])

  def chunk_items(%{queue: queue, current: current} = acc, _)
      when queue == [] and length(current) > 0 do
    acc
    |> Queue.complete_current()
    |> Map.get(:done)
  end

  def chunk_items(%{queue: queue, done: done}, _) when queue == [],
    do: done

  def chunk_items(%{queue: [head, next | _], current: current} = acc, opts) do
    max_text_count = Keyword.get(opts, :max_tokens, 4096)
    current_count = Tokens.count(current)
    next_count = Tokens.count(next)
    head_count = Tokens.count(head)

    (current_count + head_count + next_count > max_text_count)
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
    |> chunk_items(opts)
  end

  def chunk_items(%{queue: [head | _], current: current} = acc, opts) do
    max_text_count = Keyword.get(opts, :max_tokens, 4096)
    current_count = Tokens.count(current)
    head_count = Tokens.count(head)

    (current_count + head_count > max_text_count)
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
    |> chunk_items(opts)
  end

  @impl true
  def prompt_count(_opts), do: 0

  @impl true
  def prompt(_, _), do: ""
end
