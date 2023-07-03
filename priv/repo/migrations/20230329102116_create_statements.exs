defmodule OpenphoneRecorder.Repo.Migrations.CreateStatements do
  use Ecto.Migration

  def change do
    create table(:statements, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :source, :string
      add :external_id, :string
      add :content, :text
      add :occurred_at, :naive_datetime_usec
      add :type, :string
      add :conversation_id, references(:conversations, on_delete: :nothing, type: :uuid)
      add :participant_id, references(:participants, on_delete: :nothing)
      add :call_id, references(:calls, on_delete: :nothing, type: :uuid)

      timestamps(type: :naive_datetime_usec)
    end

    create index(:statements, [:conversation_id])
    create index(:statements, [:participant_id])
  end
end
