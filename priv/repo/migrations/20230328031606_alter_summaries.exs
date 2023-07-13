defmodule Discussit.Repo.Migrations.AlterSummaries do
  use Ecto.Migration

  def change do
    alter table(:summaries) do
      add :summary_id, references(:summaries, on_delete: :nothing, type: :uuid)
    end

    create(index(:summaries, [:summary_id]))
  end
end
