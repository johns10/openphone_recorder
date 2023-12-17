defmodule Discussit.Repo.Migrations.AddModelIdToTopicId do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :model_id, references(:models, on_delete: :delete_all, type: :binary_id)
      add :from_topic_id, references(:topics, on_delete: :nilify_all)
    end

    create index(:topics, [:model_id])
    create unique_index(:topics, [:from_topic_id])
  end
end
