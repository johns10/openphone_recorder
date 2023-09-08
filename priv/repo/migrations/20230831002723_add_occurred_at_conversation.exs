defmodule Discussit.Repo.Migrations.AddOccurredAtConversation do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :occurred_at, :naive_datetime
    end
  end
end
