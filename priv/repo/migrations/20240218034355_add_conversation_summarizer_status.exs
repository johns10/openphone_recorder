defmodule Discussit.Repo.Migrations.AddConversationSummarizerStatus do
  use Ecto.Migration

  def change do
    alter table(:conversation_summarizers) do
      add :status, :string
    end
  end
end
