defmodule Discussit.Repo.Migrations.AddReducerModelIdToSummarizer do
  use Ecto.Migration

  def change do
    alter table(:summarizers) do
      add :rewriter_prompt, :text
      add :reducer_model_id, references(:models, on_delete: :nilify_all, type: :binary_id)
      add :rewriter_model_id, references(:models, on_delete: :nilify_all, type: :binary_id)
    end
  end
end
