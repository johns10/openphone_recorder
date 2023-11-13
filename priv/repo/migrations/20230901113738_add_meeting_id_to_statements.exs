defmodule Discussit.Repo.Migrations.AddMeetingIdToStatements do
  use Ecto.Migration

  def change do
    alter table(:statements) do
      add :meeting_id, references(:meetings, on_delete: :nothing)
    end
  end
end
