defmodule Discussit.Repo.Migrations.AddTranscriptIdToMeeting do
  use Ecto.Migration

  def change do
    alter table(:meetings) do
      add :transcript_id, :string
    end
  end
end
