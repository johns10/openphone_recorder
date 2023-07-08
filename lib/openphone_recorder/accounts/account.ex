defmodule OpenphoneRecorder.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :name, :string
    field :plan, Ecto.Enum, values: [:free, :basic, :pro, :enterprise]

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name, :plan])
    |> validate_required([:name, :plan])
  end
end
