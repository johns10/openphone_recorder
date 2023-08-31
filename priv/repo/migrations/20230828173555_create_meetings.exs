defmodule Discussit.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings) do
      add :name, :string
      add :provider, :string
      add :occurred_at, :naive_datetime_usec
      add :upload_status, :string
      add :projector_status, :string
      add :files, :jsonb

      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_cons(:meetings, [:name, :occurred_at, :user_id])
  end
end
