defmodule Discussit.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :model_id, :integer
      add :title, :string
      add :model_title, :string
      add :summary, :string
      add :sentiment, :integer

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
