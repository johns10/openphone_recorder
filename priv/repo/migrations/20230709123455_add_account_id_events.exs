defmodule Discussit.Repo.Migrations.AddAccountIdEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :account_id, references(:accounts, on_delete: :delete_all, type: :binary_id)
    end
  end
end
