defmodule OpenphoneRecorder.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :payload, :map
    field :processed, :boolean

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:payload, :processed])
    |> validate_required([:payload])
  end
end
