defmodule Discussit.Repo.Migrations.AddNameToParticipants do
  use Ecto.Migration

  def change do
    alter table :participants do
      add :name, :string
    end
  end
end
