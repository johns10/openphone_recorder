defmodule Discussit.Repo.Migrations.CreateUserSettings do
  use Ecto.Migration

  def change do
    create table(:user_settings) do
      add :selected_account_id, references(:accounts, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:user_settings, [:selected_account_id])
    create unique_index(:user_settings, [:user_id])
  end
end
