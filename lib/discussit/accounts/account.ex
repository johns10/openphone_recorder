defmodule Discussit.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.AccountUsers.AccountUser

  @tz_options Discussit.TimeZoneOptions.tz_options()

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "accounts" do
    field :name, :string
    field :plan, Ecto.Enum, values: [:free, :basic, :pro, :enterprise]
    field :openphone_signing_secret, :string
    field :openai_api_key, :string
    field :timezone, Ecto.Enum, values: @tz_options

    has_many :account_users, AccountUser

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :plan, :openphone_signing_secret, :openai_api_key, :timezone])
    |> validate_required([:name, :plan])
  end
end
