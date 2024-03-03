defmodule Discussit.Repo.Migrations.RemoveConversationSummarizerStatus do
  use Ecto.Migration

  def change do
    alter table(:conversation_summarizers) do
      remove :status
    end
  end
end
