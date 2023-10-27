defmodule Discussit.SentenceEmbeddings.SentenceEmbedding do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sentence_embeddings" do
    field :model, Ecto.Enum, values: [:"BAAI/bge-large-en-v1.5"]
    field :status, Ecto.Enum, values: [:created, :running, :complete, :error]
    field :vector, Pgvector.Ecto.Vector
    field :statement_id, :id

    timestamps()
  end

  @doc false
  def changeset(sentence_embedding, attrs) do
    sentence_embedding
    |> cast(attrs, [:vector, :status, :model])
    |> validate_required([:vector, :status, :model])
  end
end
