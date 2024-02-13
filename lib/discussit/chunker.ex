defmodule Discussit.Chunker do
  alias Discussit.Chunker.Queue

  def apply(input, opts) do
    Keyword.get(opts, :chunkers, [])
    |> Enum.reduce([input], fn chunker, queue ->
      queue
      |> Enum.map(&impl(chunker).chunk_items(Queue.acc(&1), opts))
      |> Enum.reduce([], fn list, acc -> acc ++ list end)
    end)
  end

  @spec prompt(:daily | :test | :token_count | :weekly, any, any) :: any
  def prompt(chunker, text, opts), do: impl(chunker).prompt(text, opts)

  def prompt_count(chunker, opts), do: impl(chunker).prompt_count(opts)

  defp impl(:daily), do: Discussit.Chunker.Daily
  defp impl(:weekly), do: Discussit.Chunker.Weekly
  defp impl(:monthly), do: Discussit.Chunker.Monthly
  defp impl(:token_count), do: Discussit.Chunker.TokenCount
  defp impl(:none), do: Discussit.Chunker.None
  defp impl(:test), do: Discussit.Chunker.Test
end
