defmodule Discussit.Repo.Migrations.AddUnprocessableAllStopwordsDefaults do
  use Ecto.Migration

  def change do
    alter table(:statements) do
      modify :all_stopwords, :boolean, default: false
      modify :unprocessable, :boolean, default: false
    end
  end
end
