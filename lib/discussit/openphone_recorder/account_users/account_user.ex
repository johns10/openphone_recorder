defmodule Discussit.AccountUsers.AccountUser do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Users.User
  alias Discussit.Accounts.Account

  schema "account_users" do
    belongs_to :user, User
    belongs_to :account, Account, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(account_user, attrs) do
    account_user
    |> cast(attrs, [:account_id, :user_id])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:user_id)
    |> validate_required([])
  end
end
