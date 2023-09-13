defmodule Discussit.Participants.Participant do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Meetings.Meeting
  alias Discussit.Conversations.Conversation
  alias Discussit.PhoneNumbers.PhoneNumber
  alias Discussit.Contacts.Contact

  schema "participants" do
    field :name, :string
    
    belongs_to :conversation, Conversation, type: :binary_id
    belongs_to :phone_number, PhoneNumber, type: :binary_id
    belongs_to :contact, Contact, type: :binary_id
    belongs_to :meeting, Meeting

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:conversation_id, :phone_number_id, :contact_id, :name, :meeting_id])
    |> validate_required([])
    |> unique_constraint([:conversation_id, :phone_number_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:phone_number_id)
    |> foreign_key_constraint(:contact_id)
    |> foreign_key_constraint(:meeting_id)
  end

  def render_for_prompt(%__MODULE__{phone_number: nil}),
    do: raise("Cannot render participant without associated phone number")

  def render_for_prompt(%__MODULE__{phone_number: %PhoneNumber{contacts: [contact]}, contact: nil}),
      do: Contact.render_for_prompt(contact)

  def render_for_prompt(%__MODULE__{phone_number: phone_number, contact: nil}),
    do: PhoneNumber.render_for_prompt(phone_number)

  def render_for_prompt(%__MODULE__{contact: contact}),
    do: Contact.render_for_prompt(contact)
end
