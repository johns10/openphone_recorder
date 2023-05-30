defmodule OpenphoneRecorder.Repo.Migrations.CreateSummaries do
  use Ecto.Migration

  def change do
    create table :summaries, primary_key: false  do
      add :id, :uuid, primary_key: true 
      add :content, :text 
      add :type, :string 
      add :params, :map 
      add :level, :integer 

      timestamps()
    end
  end
end
