defmodule OpenphoneRecorder.Participants.Participant do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Conversations.Conversation
  alias OpenphoneRecorder.PhoneNumbers.PhoneNumber

  schema "participants" do
    belongs_to :conversation, Conversation, type: :binary_id
    belongs_to :phone_number, PhoneNumber, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:conversation_id, :phone_number_id])
    |> validate_required([])
    |> unique_constraint([:conversation_id, :phone_number_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:phone_number_id)
  end
end
