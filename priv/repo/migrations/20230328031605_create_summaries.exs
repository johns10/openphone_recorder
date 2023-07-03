defmodule OpenphoneRecorder.Repo.Migrations.CreateSummaries do
  use Ecto.Migration

  def change do
    create table(:summaries, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :content, :text
      add :params, :map
      add :level, :integer
      add :conversation_summarizer_id, references(:conversation_summarizers, on_delete: :nothing)
      add :tsrange, :tsrange

      timestamps()
    end
  end
end
