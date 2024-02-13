defmodule Discussit.Chunker.None do
  @behaviour Discussit.Chunker.Behaviour

  @impl true
  def chunk_items(%{queue: queue}, _), do: [queue]
end
