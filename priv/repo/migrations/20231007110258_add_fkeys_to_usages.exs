defmodule Discussit.Repo.Migrations.AddFkeysToUsages do
  use Ecto.Migration

  def change do
    alter table :usages do
      add :summary_id, references(:summaries, on_delete: :nothing, type: :uuid)
      add :embedding_id, references(:embeddings, on_delete: :nothing)
    end
  end
end
