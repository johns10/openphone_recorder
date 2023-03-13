defmodule OpenphoneRecorder.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :payload, :map

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:payload])
    |> validate_required([:payload])
  end
end
