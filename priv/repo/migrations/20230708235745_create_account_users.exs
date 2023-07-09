defmodule OpenphoneRecorder.Repo.Migrations.CreateAccountUsers do
  use Ecto.Migration

  def change do
    create table(:account_users) do
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:account_users, [:account_id])
    create index(:account_users, [:user_id])
  end
end
