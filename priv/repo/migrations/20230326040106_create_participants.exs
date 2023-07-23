defmodule Discussit.Repo.Migrations.CreateParticipants do
  use Ecto.Migration

  def change do
    create table(:participants) do
      add :conversation_id, references(:conversations, on_delete: :nothing, type: :uuid)
      add :phone_number_id, references(:phone_numbers, on_delete: :nothing, type: :uuid)

      timestamps(type: :naive_datetime_usec)
    end

    create unique_index(:participants, [:conversation_id, :phone_number_id])
    create index(:participants, [:conversation_id])
    create index(:participants, [:phone_number_id])
  end
end
