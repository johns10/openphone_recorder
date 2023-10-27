defmodule Discussit.Repo.Migrations.CreateSentenceEmbeddings do
  use Ecto.Migration

  def change do
    create table(:sentence_embeddings) do
      add :vector, :vector, size: 384
      add :status, :string
      add :model, :string
      add :statement_id, references(:statements, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:sentence_embeddings, [:statement_id])
  end
end
