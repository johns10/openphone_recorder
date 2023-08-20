defmodule Discussit.Repo.Migrations.CallFiles do
  use Ecto.Migration

  def change do
    alter table(:calls) do
      add :call_recording, :map
      add :voicemail, :map
      add :metadata, :jsonb
      add :status, :string
      add :from_channel, :string
      add :to_channel, :string
    end
  end
end
