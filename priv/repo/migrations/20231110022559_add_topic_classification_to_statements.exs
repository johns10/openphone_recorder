defmodule Discussit.Repo.Migrations.AddTopicClassificationToStatements do
  use Ecto.Migration

  def change do
    alter table(:statements) do
      add :model_topic_id, references(:topics, on_delete: :nilify_all)
      add :labelled_topic_id, references(:topics, on_delete: :nothing)
    end

    create index(:statements, [:model_topic_id])
    create index(:statements, [:labelled_topic_id])
  end
end
