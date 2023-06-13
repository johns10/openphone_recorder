defmodule OpenphoneRecorder.Repo.Migrations.CreateSummaries do
  use Ecto.Migration

  def change do
    create table(:summaries, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string
      add :content, :text
      add :params, :map
      add :level, :integer
      add :summarizer_id, references(:summarizers, on_delete: :nothing)

      timestamps()
    end
  end
end
