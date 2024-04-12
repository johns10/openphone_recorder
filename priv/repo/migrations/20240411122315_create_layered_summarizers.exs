defmodule Discussit.Repo.Migrations.CreateLayeredSummarizers do
  use Ecto.Migration

  def change do
    create table(:layered_summarizers) do
      add :name, :string

      timestamps()
    end
  end
end
