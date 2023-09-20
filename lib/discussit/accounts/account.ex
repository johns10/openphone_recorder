defmodule Discussit.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Credits.Credit
  alias Discussit.Usages.Usage
  alias Discussit.AccountUsers.AccountUser
  alias Discussit.Users.User

  @tz_options Discussit.TimeZoneOptions.tz_options()

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "accounts" do
    field :name, :string
    field :plan, Ecto.Enum, values: [:free, :basic, :pro, :enterprise]
    field :openphone_signing_secret, :string
    field :openai_api_key, :string
    field :timezone, Ecto.Enum, values: @tz_options
    field :stripe_customer_id, :string
    field :default_payment_method_id, :string

    field :available_credits, :float, virtual: true

    belongs_to :billing_user, User
    has_many :account_users, AccountUser
    has_many :usages, Usage
    has_many :credits, Credit

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :name,
      :plan,
      :openphone_signing_secret,
      :openai_api_key,
      :timezone,
      :billing_user_id,
      :stripe_customer_id,
      :default_payment_method_id
    ])
    |> foreign_key_constraint(:billing_user_id)
    |> validate_required([:name, :plan])
  end
end
