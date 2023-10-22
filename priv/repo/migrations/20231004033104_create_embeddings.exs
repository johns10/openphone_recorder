defmodule Discussit.Repo.Migrations.CreateEmbeddings do
  use Ecto.Migration

  def change do
    create table(:embeddings) do
      add :vector, :vector, size: 1024
      add :status, :string
      add :model, :string
      add :statement_id, references(:statements, on_delete: :nothing, type: :uuid)
      add :summary_id, references(:summaries, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:embeddings, [:statement_id])
    create index(:embeddings, [:summary_id])
  end
end
