defmodule Discussit.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :model_id, :integer
      add :title, :string
      add :model_title, :string
      add :description, :text
      add :model_description, :text
      add :sentiment, :integer
      add :keywords, :jsonb

      add :account_id, references(:accounts, on_delete: :nilify_all, type: :uuid)

      timestamps()
    end

    alter table(:statements) do
      add :topic_id, references(:topics, on_delete: :nilify_all)
    end

    alter table(:topics) do
      add :parent_topic_id, references(:topics, on_delete: :nilify_all)
    end
  end
end
