defmodule OpenphoneRecorder.Repo.Migrations.ModifyEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :processed, :bool, default: false
    end
  end
end
