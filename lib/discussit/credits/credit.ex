defmodule Discussit.Credits.Credit do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Accounts.Account
  alias Discussit.Users.User

  schema "credits" do
    field :product_id, :string
    field :purchased_at, :naive_datetime
    field :quantity, :float
    belongs_to :account, Account, type: :binary_id
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(credit, attrs) do
    credit
    |> cast(attrs, [:user_id, :account_id, :product_id, :quantity, :purchased_at])
    |> validate_required([:product_id, :quantity, :purchased_at])
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:user_id)
  end
end
