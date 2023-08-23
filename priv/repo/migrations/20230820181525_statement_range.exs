defmodule Discussit.Repo.Migrations.StatementRange do
  use Ecto.Migration

  def change do
    alter table :statements do
      add :ts_range, :tsrange
    end
  end
end
