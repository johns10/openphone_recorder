defmodule Discussit.Repo.Migrations.AddTranscriptIds do
  use Ecto.Migration

  def change do
    alter table(:meetings) do
      remove :transcript_id, :string
      remove :segments
      add :transcript_ids, {:array, :string}
    end

    alter table(:calls) do
      add :transcript_ids, {:array, :string}
    end
  end
end
