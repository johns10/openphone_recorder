defmodule OpenphoneRecorder.Repo.Migrations.CreateConversationSummarizers do
  use Ecto.Migration

  def change do
    create table(:conversation_summarizers) do
      add :summarizer_id, references(:summarizers, on_delete: :nothing)
      add :conversation_id, references(:conversations, on_delete: :nothing, type: :uuid)

      timestamps(type: :naive_datetime_usec)
    end

    create unique_index(:conversation_summarizers, [:summarizer_id, :conversation_id])
    create index(:conversation_summarizers, [:summarizer_id])
    create index(:conversation_summarizers, [:conversation_id])
  end
end
