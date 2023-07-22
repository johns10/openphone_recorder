defmodule Discussit.AccountUsers.AccountUserForm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :email, :string
    field :account_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(account_user, attrs) do
    account_user
    |> cast(attrs, [:email, :account_id])
    |> validate_required([:email, :account_id])
  end
end
