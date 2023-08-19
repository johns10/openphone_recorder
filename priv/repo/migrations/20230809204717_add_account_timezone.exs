defmodule Discussit.Repo.Migrations.AddAccountTimezone do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :timezone, :string
    end
  end
end
