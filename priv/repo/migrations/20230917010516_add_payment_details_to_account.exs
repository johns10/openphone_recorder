defmodule Discussit.Repo.Migrations.AddPaymentDetailsToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :billing_user_id, references(:users, on_delete: :nilify_all)
    end
  end
end
