defmodule OpenphoneRecorder.AccountUsers.AccountUser do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Users.User
  alias OpenphoneRecorder.Accounts.Account

  schema "account_users" do

    belongs_to :user, User
    belongs_to :account, Account

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
