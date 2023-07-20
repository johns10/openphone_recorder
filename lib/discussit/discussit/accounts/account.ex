defmodule Discussit.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.AccountUsers.AccountUser

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "accounts" do
    field :name, :string
    field :plan, Ecto.Enum, values: [:free, :basic, :pro, :enterprise]

    has_many :account_users, AccountUser

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :plan])
    |> validate_required([:name, :plan])
  end
end
