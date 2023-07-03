defmodule OpenphoneRecorder.Repo.Migrations.CreatePhoneNumbers do
  use Ecto.Migration

  def change do
    create table(:phone_numbers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :external_id, :string
      add :value, :string
      add :source, :string
      add :contact_id, references(:contacts, on_delete: :nothing, type: :uuid)

      timestamps(type: :naive_datetime_usec)
    end

    create unique_index(:phone_numbers, [:id])
    create unique_index(:phone_numbers, [:external_id, :source])
    create index(:phone_numbers, [:contact_id])
  end
end
