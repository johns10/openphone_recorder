defmodule Discussit.Repo.Migrations.AddAccountIdToSummarizer do
  use Ecto.Migration

  def change do
    alter table(:summarizers) do
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)
    end

    create index(:summarizers, [:account_id])
  end
end
