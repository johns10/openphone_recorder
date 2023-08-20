defmodule Discussit.Repo.Migrations.CallFiles do
  use Ecto.Migration

  def change do
    alter table(:calls) do
      add :call_recording, :map
      add :voicemail, :map
      add :metadata, :jsonb
      add :status, :string
    end
  end
end
