defmodule Discussit.Repo.Migrations.RenameParentTopicId do
  use Ecto.Migration

  def change do
    rename table(:topics), :parent_topic_id, to: :parent_id
  end
end
