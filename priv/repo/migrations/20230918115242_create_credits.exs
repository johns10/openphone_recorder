defmodule Discussit.Repo.Migrations.CreateCredits do
  use Ecto.Migration

  def change do
    create table(:credits) do
      add :product_id, :string
      add :quantity, :float
      add :purchased_at, :naive_datetime
      add :account_id, references(:accounts, on_delete: :nothing, type: :uuid)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:credits, [:account_id])
    create index(:credits, [:user_id])
  end
end
