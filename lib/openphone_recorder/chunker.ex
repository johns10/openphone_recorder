defmodule OpenphoneRecorder.Chunker do
  alias OpenphoneRecorder.Chunker.Queue

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

  def prompt(chunker, text, opts), do: impl(chunker).prompt(text, opts)

  def prompt_count(chunker, opts), do: impl(chunker).prompt_count(opts)

  defp impl(:daily), do: OpenphoneRecorder.Chunker.Daily
  defp impl(:token_count), do: OpenphoneRecorder.Chunker.TokenCount
  defp impl(:test), do: OpenphoneRecorder.Chunker.Test
end
