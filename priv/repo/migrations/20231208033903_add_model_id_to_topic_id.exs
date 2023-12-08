defmodule Discussit.Repo.Migrations.AddModelIdToTopicId do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :model_id, references(:models, on_delete: :delete_all, type: :binary_id)
    end

    create index(:topics, [:model_id])
  end
end
