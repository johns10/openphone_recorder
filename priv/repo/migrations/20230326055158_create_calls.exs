defmodule OpenphoneRecorder.Repo.Migrations.CreateCalls do
  use Ecto.Migration

  def change do
    create table(:calls, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :source, :string
      add :external_id, :string
      add :answered_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
      add :conversation_id, references(:conversations, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:calls, [:conversation_id])
  end
end
