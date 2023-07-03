defmodule OpenphoneRecorder.Repo.Migrations.CreateStatementSummaries do
  use Ecto.Migration

  def change do
    create table(:statement_summaries) do
      add :summary_id, references(:summaries, on_delete: :nothing, type: :uuid)
      add :statement_id, references(:statements, on_delete: :nothing, type: :uuid)

      timestamps(type: :naive_datetime_usec)
    end

    create index(:statement_summaries, [:summary_id])
    create index(:statement_summaries, [:statement_id])
  end
end
