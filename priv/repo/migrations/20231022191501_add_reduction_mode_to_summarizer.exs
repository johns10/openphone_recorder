defmodule Discussit.Repo.Migrations.AddReductionModeToSummarizer do
  use Ecto.Migration

  def change do
    alter table(:summarizers) do
      add :reduction_mode, :string
    end
  end
end
