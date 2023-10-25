defmodule Discussit.Topics.Topic do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Accounts.Account

  schema "topics" do
    field :model_id, :integer
    field :sentiment, :integer
    field :summary, :string
    field :title, :string
    field :model_title, :string

    belongs_to :parent_topic, __MODULE__
    belongs_to :account, Account, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [
      :model_id,
      :title,
      :model_title,
      :summary,
      :sentiment,
      :parent_topic_id,
      :account_id
    ])
    |> foreign_key_constraint(:parent_topic_id)
    |> validate_required([:model_id, :model_title])
  end
end
