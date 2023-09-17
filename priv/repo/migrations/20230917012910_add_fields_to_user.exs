defmodule Discussit.Repo.Migrations.AddFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :timezone, :string
      add :selected_account_id, references(:accounts, on_delete: :nilify_all, type: :uuid)
    end
  end
end
