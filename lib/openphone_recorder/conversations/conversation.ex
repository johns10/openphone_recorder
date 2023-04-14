defmodule OpenphoneRecorder.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Participants.Participant

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "conversations" do
    field :external_id, :string
    field :source, Ecto.Enum, values: [:openphone]

    has_many :participants, Participant
    has_many :phone_numbers, through: [:participants, :phone_number]
    has_many :contacts, through: [:phone_numbers, :contact]
    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:source, :external_id])
    |> cast_id()
    |> unique_constraint([:id], name: :conversations_pkey)
    |> validate_required([:source, :external_id])
  end

  defp cast_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        external_id = get_change(changeset, :external_id)
        source = get_change(changeset, :source)

        case {source, external_id} do
          {:openphone, external_id} when is_atom(source) and is_binary(external_id) ->
            put_change(changeset, :id, UUID.uuid5(nil, "openphone-" <> external_id))

          _ ->
            add_error(changeset, :id, "insufficient args to generate id")
        end

      _ ->
        changeset
    end
  end
end
