defmodule Discussit.Topics.Topic do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Accounts.Account
  alias Discussit.Statements.Statement

  schema "topics" do
    field :model_id, :integer
    field :sentiment, :integer
    field :title, :string
    field :model_title, :string
    field :description, :string
    field :model_description, :string
    field :keywords, {:array, :map}

    belongs_to :parent_topic, __MODULE__
    belongs_to :account, Account, type: :binary_id

    has_many :statements, Statement

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [
      :model_id,
      :title,
      :model_title,
      :description,
      :model_description,
      :sentiment,
      :parent_topic_id,
      :account_id,
      :keywords,
      :account_id
    ])
    |> cast_keywords()
    |> foreign_key_constraint(:parent_topic_id)
    |> validate_required([:model_id, :model_title])
  end

  def cast_keywords(changeset) do
    case get_change(changeset, :keywords) do
      nil ->
        changeset

      keywords ->
        casted_keywords =
          Enum.map(keywords, fn %{keyword: keyword, probability: probability} ->
            {float, _} = Float.parse(probability)
            %{keyword: keyword, probability: float}
          end)

        put_change(changeset, :keywords, casted_keywords)
    end
  end
end
