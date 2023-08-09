defmodule Discussit.Repo.Migrations.AddParticipantsToCall do
  use Ecto.Migration

  def change do
    alter table(:calls) do
      add :from_participant_id, references(:participants, on_delete: :nothing)
      add :to_participant_id, references(:participants, on_delete: :nothing)
    end
  end
end
