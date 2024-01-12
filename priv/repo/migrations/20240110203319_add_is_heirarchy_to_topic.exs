defmodule Discussit.Repo.Migrations.AddIsHeirarchyToTopic do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :is_hierarchy, :boolean
    end
  end
end
