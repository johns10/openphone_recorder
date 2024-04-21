defmodule Discussit.Embeddings.Job do
  use Oban.Worker, queue: :embeddings
  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    FLAME.call(EmbeddingsRunner, fn ->
      Discussit.Embeddings.Impl.embed_statements()
    end)

    :ok
  end
end
