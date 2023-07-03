defmodule OpenphoneRecorder.Participants.Participant do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Conversations.Conversation
  alias OpenphoneRecorder.PhoneNumbers.PhoneNumber

  schema "participants" do
    belongs_to :conversation, Conversation, type: :binary_id
    belongs_to :phone_number, PhoneNumber, type: :binary_id

    timestamps(type: :naive_datetime_usec)
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

  def render_for_prompt(%__MODULE__{phone_number: nil}),
    do: raise("Cannot render participant without associated contact info")

  def render_for_prompt(%__MODULE__{phone_number: phone_number}),
    do: PhoneNumber.render_for_prompt(phone_number)
end
