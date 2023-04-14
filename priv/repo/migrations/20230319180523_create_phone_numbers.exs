defmodule OpenphoneRecorder.Repo.Migrations.CreatePhoneNumbers do
  use Ecto.Migration

  def change do
    create table(:phone_numbers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :external_id, :string
      add :phone_number, :string
      add :source, :string

      timestamps()
    end

    create unique_index(:phone_numbers, [:id])
    create unique_index(:phone_numbers, [:external_id, :source])
  end
end
