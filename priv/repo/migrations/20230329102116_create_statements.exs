defmodule OpenphoneRecorder.Repo.Migrations.CreateStatements do
  use Ecto.Migration

  def change do
    create table(:statements) do
      add(:content, :string)
      add(:occurred_at, :utc_datetime)
      add(:type, :string)
      add(:conversation_id, references(:conversations, on_delete: :nothing, type: :uuid))
      add(:participant_id, references(:participants, on_delete: :nothing))
      add(:call_id, references(:calls, on_delete: :nothing, type: :uuid))

      timestamps()
    end

    create(index(:statements, [:conversation_id]))
    create(index(:statements, [:participant_id]))
  end
end
