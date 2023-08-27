defmodule Discussit.Repo.Migrations.SkipEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :skipped, :boolean, default: false
    end
  end
end
