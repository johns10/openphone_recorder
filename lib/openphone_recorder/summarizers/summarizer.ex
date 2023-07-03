defmodule OpenphoneRecorder.Summarizers.Summarizer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "summarizers" do
    field :prompt, :string
    field :chunker, Ecto.Enum, values: [:temporal, :topical]

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(summarizer, attrs) do
    summarizer
    |> cast(attrs, [:prompt, :chunker])
    |> validate_required([:prompt])
  end
end
