defmodule Discussit.Repo.Migrations.MoveContactIdToParticipant do
  use Ecto.Migration

  def change do
    drop(index(:phone_numbers, [:contact_id]))

    alter table(:phone_numbers) do
      remove(:contact_id, references(:contacts, type: :uuid))
    end

    alter table(:participants) do
      add(:contact_id, references(:contacts, on_delete: :nothing, type: :uuid))
    end

    create(index(:participants, [:contact_id]))
  end
end
