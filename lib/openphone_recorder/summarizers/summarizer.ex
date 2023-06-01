defmodule OpenphoneRecorder.Summarizers.Summarizer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "summarizers" do
    field :prompt, :string

    timestamps()
  end

  @doc false
  def changeset(summarizer, attrs) do
    summarizer
    |> cast(attrs, [:prompt])
    |> validate_required([:prompt])
  end
end
