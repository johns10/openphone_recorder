defmodule Discussit.Summarizers.Summarizer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Models.Model
  alias Discussit.Accounts.Account

  schema "summarizers" do
    field :name, :string
    field :prompt, :string
    field :reducer_prompt, :string
    field :rewriter_prompt, :string

    field :chunker, Ecto.Enum,
      values: [:none, :daily, :weekly, :monthly, :yearly, :topical, :token_count]

    field :percentage_reduction, :float
    field :fixed_reduction, :integer
    field :reduction_mode, Ecto.Enum, values: [:percentage, :fixed]

    belongs_to :account, Account, type: :binary_id
    belongs_to :model, Model, type: :binary_id
    belongs_to :reducer_model, Model, type: :binary_id
    belongs_to :rewriter_model, Model, type: :binary_id
    belongs_to :summarizer, __MODULE__

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(summarizer, attrs) do
    summarizer
    |> cast(attrs, [
      :name,
      :prompt,
      :reducer_prompt,
      :rewriter_prompt,
      :chunker,
      :percentage_reduction,
      :fixed_reduction,
      :reduction_mode,
      :account_id,
      :model_id,
      :reducer_model_id,
      :rewriter_model_id
    ])
    |> foreign_key_constraint(:account_id)
    |> validate_required([:prompt])
  end
end
