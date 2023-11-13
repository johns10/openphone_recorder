defmodule Discussit.Repo.Migrations.AddMeetingIdToParticipants do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add :meeting_id, references(:meetings, on_delete: :nothing)
    end
  end
end
