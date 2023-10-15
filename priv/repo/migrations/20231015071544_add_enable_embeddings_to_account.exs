defmodule Discussit.Repo.Migrations.AddEnableEmbeddingsToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :enable_embeddings, :boolean
    end
  end
end
