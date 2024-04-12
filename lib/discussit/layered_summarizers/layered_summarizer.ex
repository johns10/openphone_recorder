defmodule Discussit.LayeredSummarizers.LayeredSummarizer do
  alias Discussit.Accounts.Account
  use Ecto.Schema
  import Ecto.Changeset

  schema "layered_summarizers" do
    field :name, :string
    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(layered_summarizer, attrs) do
    layered_summarizer
    |> cast(attrs, [:name, :account_id])
    |> validate_required([:name, :account_id])
  end
end
