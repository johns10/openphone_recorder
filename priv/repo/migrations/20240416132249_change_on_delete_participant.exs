defmodule Discussit.Repo.Migrations.ChangeOnDeleteParticipant do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      modify :contact_id, references(:contacts, on_delete: :nilify_all, type: :uuid),
        from: references(:contacts, on_delete: :nothing)
    end
  end
end
