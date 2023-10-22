defmodule Discussit.Embeddings.Embedding do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Statements.Statement
  alias Discussit.Summaries.Summary

  schema "embeddings" do
    field :vector, Pgvector.Ecto.Vector
    field :status, Ecto.Enum, values: [:created, :running, :complete, :error]
    field :model, Ecto.Enum, values: [:"BAAI/bge-large-en-v1.5"]

    belongs_to :statement, Statement, type: :binary_id
    belongs_to :summary, Summary, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(embedding, attrs) do
    embedding
    |> cast(attrs, [:vector, :status, :model, :statement_id, :summary_id])
    |> foreign_key_constraint(:statement_id)
    |> foreign_key_constraint(:summary_id)
    |> validate_required([:status])
  end
end
