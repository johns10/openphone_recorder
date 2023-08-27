defmodule Discussit.Repo.Migrations.CreateUsages do
  use Ecto.Migration

  def change do
    create table(:usages) do
      add :provider, :string
      add :model, :string
      add :product, :string
      add :meta, :map
      add :total, :float
      add :account_id, references(:accounts, on_delete: :nothing, type: :uuid)

      timestamps()
    end
  end
end
