defmodule OpenphoneRecorder.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :external_id, :string
      add :source, :string
      timestamps()
    end
  end
end
