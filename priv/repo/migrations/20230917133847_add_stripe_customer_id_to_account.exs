defmodule Discussit.Repo.Migrations.AddStripeCustomerIdToAccount do
  use Ecto.Migration

  def change do
    alter table :accounts do
      add :stripe_customer_id, :string
    end
  end
end
