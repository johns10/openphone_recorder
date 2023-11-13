defmodule Discussit.Repo.Migrations.AddAllStopwords do
  use Ecto.Migration

  def change do
    alter table(:statements) do
      add :all_stopwords, :boolean
    end
  end
end
