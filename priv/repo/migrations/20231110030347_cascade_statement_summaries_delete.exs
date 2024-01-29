defmodule Discussit.Repo.Migrations.CascadeStatementSummariesDelete do
  use Ecto.Migration

  def change do
    alter table(:statement_summaries) do
      modify :summary_id, references(:summaries, on_delete: :delete_all, type: :uuid),
        from: references(:summaries, on_delete: :nothing, type: :uuid)
    end
  end
end
