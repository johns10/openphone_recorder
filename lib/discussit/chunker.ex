defmodule Discussit.Chunker do
  alias Discussit.Chunker.Queue

  def apply(input, opts) do
    chunkers = Keyword.get(opts, :chunkers, [])

    Enum.reduce(chunkers, [input], fn chunker, queue ->
      queue
      |> chunk_items(chunker, opts)
      |> Enum.reduce([], fn list, acc -> acc ++ list end)
    end)
  end

  defp chunk_items(queue, chunker, opts) do
    Enum.map(queue, &impl(chunker).chunk_items(Queue.acc(&1), opts))
  end

  @spec prompt(:daily | :test | :token_count | :weekly, any, any) :: any
  def prompt(chunker, text, opts), do: impl(chunker).prompt(text, opts)

  def prompt_count(chunker, opts), do: impl(chunker).prompt_count(opts)

  defp impl(:daily), do: Discussit.Chunker.Daily
  defp impl(:weekly), do: Discussit.Chunker.Weekly
  defp impl(:monthly), do: Discussit.Chunker.Monthly
  defp impl(:token_count), do: Discussit.Chunker.TokenCount
  defp impl(:test), do: Discussit.Chunker.Test
end
