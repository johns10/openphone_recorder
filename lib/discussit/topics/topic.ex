defmodule Discussit.Topics.Topic do
  @moduledoc """
  `topic_model_id` represents the topic id assigned by the topic model.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Accounts.Account
  alias Discussit.Statements.Statement
  alias Discussit.Models.Model

  @derive {Jason.Encoder,
           only: [
             :id,
             :topic_model_id,
             :title,
             :model_title,
             :description,
             :model_description
           ]}
  schema "topics" do
    field :topic_model_id, :integer
    field :sentiment, :integer
    field :title, :string
    field :model_title, :string
    field :description, :string
    field :model_description, :string
    field :keywords, {:array, :map}

    field :summarizer_status, Ecto.Enum,
      values: [:not_started, :started],
      virtual: true,
      default: :not_started

    belongs_to :parent_topic, __MODULE__
    belongs_to :account, Account, type: :binary_id
    belongs_to :model, Model

    has_many :statements, Statement
    has_many :model_statements, Statement, foreign_key: :trained_topic_id
    has_many :labelled_statements, Statement, foreign_key: :labelled_topic_id

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [
      :topic_model_id,
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
    |> no_assoc_constraint(:labelled_statements, name: :statements_labelled_topic_id_fkey)
    |> validate_required([])
  end

  def cast_keywords(changeset) do
    case get_change(changeset, :keywords) do
      nil ->
        changeset

      keywords ->
        casted_keywords =
          Enum.map(keywords, fn
            %{"keyword" => k, "probability" => p} -> cast_keyword(k, p)
            %{keyword: k, probability: p} -> cast_keyword(k, p)
          end)

        put_change(changeset, :keywords, casted_keywords)
    end
  end

  def cast_keyword(keyword, probability) when is_binary(probability) do
    {float, _} = Float.parse(probability)
    %{keyword: keyword, probability: float}
  end

  def cast_keyword(keyword, probability) when is_float(probability) do
    %{keyword: keyword, probability: probability}
  end
end
