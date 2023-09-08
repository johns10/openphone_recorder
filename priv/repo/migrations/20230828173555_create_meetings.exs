defmodule Discussit.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings) do
      add :name, :string
      add :source, :string
      add :occurred_at, :naive_datetime_usec
      add :upload_status, :string
      add :projector_status, :string
      add :files, :jsonb
      add :segments, :jsonb
      add :external_id, :string

      add :user_id, references(:users, on_delete: :nothing)
      add :account_id, references(:accounts, on_delete: :nothing, type: :uuid)
      add :conversation_id, references(:conversations, on_delete: :nothing, type: :uuid)

      timestamps(type: :naive_datetime_usec)
    end

    create unique_index(:meetings, [:name, :occurred_at, :user_id])
  end
end
