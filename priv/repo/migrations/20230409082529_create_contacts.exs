defmodule OpenphoneRecorder.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :full_name, :string
      add :external_id, :string
      add :source, :string

      timestamps()
    end
  end
end
