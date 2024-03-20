defmodule Discussit.Repo.Migrations.AddConversationName do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :name, :string
    end
  end
end
