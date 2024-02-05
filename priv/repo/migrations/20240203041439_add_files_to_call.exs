defmodule Discussit.Repo.Migrations.AddFilesToCall do
  use Ecto.Migration

  def change do
    alter table(:calls) do
      add :files, :map
    end
  end
end
