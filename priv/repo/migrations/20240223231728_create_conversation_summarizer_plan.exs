defmodule Discussit.Repo.Migrations.CreateConversationSummarizerPlan do
  use Ecto.Migration

  def change do
    create table(:conversation_summarizer_plans) do
      add :name, :string

      timestamps()
    end
  end
end
