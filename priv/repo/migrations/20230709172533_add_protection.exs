defmodule OpenphoneRecorder.Repo.Migrations.AddProtection do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)
    end

    alter table(:conversations) do
      add :account_id, references(:accounts, on_delete: :nothing, type: :binary_id)
    end
  end
end
