defmodule Discussit.Repo.Migrations.AddDefaultPaymentIdToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :default_payment_method_id, :string
    end
  end
end
