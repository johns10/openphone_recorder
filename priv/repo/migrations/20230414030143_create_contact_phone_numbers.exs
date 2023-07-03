defmodule OpenphoneRecorder.Repo.Migrations.CreateContactPhoneNumbers do
  use Ecto.Migration

  def change do
    create table(:contact_phone_numbers) do
      add :phone_number_id, references(:phone_numbers, on_delete: :nothing, type: :uuid)
      add :contact_id, references(:contacts, on_delete: :nothing, type: :uuid)

      timestamps(type: :naive_datetime_usec)
    end

    create index(:contact_phone_numbers, [:phone_number_id])
    create index(:contact_phone_numbers, [:contact_id])
    create unique_index(:contact_phone_numbers, [:contact_id, :phone_number_id])
  end
end
