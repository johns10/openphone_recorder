defmodule Discussit.Repo.Migrations.AddTrainedIdsToModel do
  use Ecto.Migration

  def change do
    alter table(:models) do
      add :trained_ids, {:array, :string}
    end
  end
end
