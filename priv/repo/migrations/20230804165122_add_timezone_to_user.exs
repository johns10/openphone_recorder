defmodule Discussit.Repo.Migrations.AddTimezoneToUserSetting do
  use Ecto.Migration

  def change do
    alter table(:user_settings) do
      add :timezone, :string
    end
  end
end
