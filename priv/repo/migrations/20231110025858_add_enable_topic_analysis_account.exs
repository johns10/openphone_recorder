defmodule Discussit.Repo.Migrations.AddEnableTopicAnalysisAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :enable_topic_analysis, :boolean
    end
  end
end
