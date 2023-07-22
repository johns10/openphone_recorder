defmodule Discussit.Repo.Migrations.AddOpenphoneSigningSecret do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :openphone_signing_secret, :string
    end
  end
end
