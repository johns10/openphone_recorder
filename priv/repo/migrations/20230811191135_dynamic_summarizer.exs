defmodule Discussit.Repo.Migrations.DynamicSummarizer do
  use Ecto.Migration

  def up do
    alter table(:summarizers) do
      modify :prompt, :text
      add :percentage_reduction, :float
      add :fixed_reduction, :integer
      add :reducer_prompt, :text
      add :summarizer_id, references(:summarizers, on_delete: :nothing)
    end
  end

  def down do
    alter table(:summarizers) do
      modify :prompt, :string
      remove :percentage_reduction, :float
      remove :fixed_reduction, :integer
      remove :reducer_prompt, :text
      remove :summarizer_id, references(:summarizers, on_delete: :nothing)
    end
  end
end
