defmodule Discussit.Repo.Migrations.ChangeParticipantMeetingNillify do
  use Ecto.Migration

  def up do
    drop constraint(:participants, "participants_meeting_id_fkey")

    alter table(:participants) do
      modify :meeting_id, references(:meetings, on_delete: :nilify_all)
    end
  end

  def down do
    drop constraint(:participants, "participants_meeting_id_fkey")

    alter table(:participants) do
      modify :meeting_id, references(:meetings, on_delete: :nothing)
    end
  end
end
