defmodule OpenphoneRecorder.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :plan, :string

      timestamps()
    end
  end
end
