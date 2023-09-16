defmodule Discussit.Repo.Migrations.RemoveConversationSummarizersOnDelete do
  use Ecto.Migration

  def up do
    drop constraint(:conversation_summarizers, "conversation_summarizers_conversation_id_fkey")

    alter table(:conversation_summarizers) do
      modify :conversation_id, references(:conversations, on_delete: :delete_all, type: :uuid)
    end
  end

  def down do
    drop constraint(:conversation_summarizers, "conversation_summarizers_conversation_id_fkey")

    alter table(:conversation_summarizers) do
      modify :conversation_id, references(:conversations, on_delete: :nothing, type: :uuid)
    end
  end
end
