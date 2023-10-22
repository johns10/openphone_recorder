defmodule Discussit.Repo.Migrations.AddStatementUnprocessable do
  use Ecto.Migration

  def change do
    alter table(:statements) do
      add :unprocessable, :boolean
    end
  end
end
