defmodule Discussit.Repo.Migrations.AddFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :timezone, :string
    end
  end
end
