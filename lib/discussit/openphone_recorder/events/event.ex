defmodule Discussit.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Accounts.Account

  schema "events" do
    field :payload, :map
    field :processed, :boolean

    belongs_to :account, Account, type: :binary_id

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:account_id, :payload, :processed])
    |> foreign_key_constraint(:account_id)
    |> validate_required([:account_id, :payload])
  end
end
