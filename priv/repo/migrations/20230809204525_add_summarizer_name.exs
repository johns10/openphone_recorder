defmodule Discussit.Repo.Migrations.AddSummarizerName do
  use Ecto.Migration

  def change do
    alter table(:summarizers) do
      add :name, :string
    end
  end
end
