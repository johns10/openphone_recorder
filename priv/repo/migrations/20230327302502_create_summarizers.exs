defmodule Discussit.Repo.Migrations.CreateSummarizers do
  use Ecto.Migration

  def change do
    create table(:summarizers) do
      add :prompt, :string
      add :chunker, :string

      timestamps(type: :naive_datetime_usec)
    end
  end
end
