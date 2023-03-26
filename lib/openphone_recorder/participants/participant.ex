defmodule OpenphoneRecorder.Participants.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participants" do
    field :conversation_id, :id
    field :phone_number_id, :id

    timestamps()
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:conversation_id, :phone_number_id])
    |> validate_required([])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:phone_nummber_id)
  end
end
