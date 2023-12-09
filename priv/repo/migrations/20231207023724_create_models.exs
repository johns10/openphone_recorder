defmodule Discussit.Repo.Migrations.CreateModels do
  use Ecto.Migration

  def change do
    create table(:models, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :model_object, :string
      add :merge_object, :string
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)

      timestamps(type: :naive_datetime_usec)
    end

    create index(:models, [:account_id])
  end
end
