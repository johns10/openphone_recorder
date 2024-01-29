defmodule Discussit.Repo.Migrations.AddTopicClassificationToStatements do
  use Ecto.Migration

  def change do
    alter table(:statements) do
      add :inferred_topic_id, references(:topics, on_delete: :nilify_all)
      add :trained_topic_id, references(:topics, on_delete: :nilify_all)
      add :labelled_topic_id, references(:topics, on_delete: :nothing)
      add :representative, :boolean
    end

    create index(:statements, [:inferred_topic_id])
    create index(:statements, [:trained_topic_id])
    create index(:statements, [:labelled_topic_id])
  end
end
