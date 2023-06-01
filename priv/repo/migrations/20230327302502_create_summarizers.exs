defmodule OpenphoneRecorder.Repo.Migrations.CreateSummarizers do
  use Ecto.Migration

  def change do
    create table(:summarizers) do
      add :prompt, :string

      timestamps()
    end
  end
end
