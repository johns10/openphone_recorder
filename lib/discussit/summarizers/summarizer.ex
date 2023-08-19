defmodule Discussit.Summarizers.Summarizer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "summarizers" do
    field :name, :string
    field :prompt, :string
    field :reducer_prompt, :string
    field :chunker, Ecto.Enum, values: [:daily, :weekly, :monthly, :yearly, :topical]
    field :percentage_reduction, :float
    field :fixed_reduction, :integer

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
      :chunker,
      :percentage_reduction,
      :fixed_reduction
    ])
    |> validate_required([:prompt])
  end
end
