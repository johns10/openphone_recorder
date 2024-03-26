defmodule Discussit.Repo.Migrations.AddModelIdToSummarizer do
  use Ecto.Migration

  def change do
    alter table(:summarizers) do
      add :model_id, references(:models, on_delete: :nilify_all, type: :binary_id)
    end
  end
end
