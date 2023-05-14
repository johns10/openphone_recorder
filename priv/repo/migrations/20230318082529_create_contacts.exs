defmodule OpenphoneRecorder.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :first_name, :string
      add :last_name, :string
      add :company, :string
      add :role, :string
      add :external_id, :string
      add :source, :string
      add :relationship, :string

      timestamps()
    end
  end
end
