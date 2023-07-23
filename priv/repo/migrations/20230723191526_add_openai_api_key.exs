defmodule Discussit.Repo.Migrations.AddOpenaiApiKey do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :openai_api_key, :string
    end
  end
end
