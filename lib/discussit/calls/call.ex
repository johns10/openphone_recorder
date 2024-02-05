defmodule Discussit.Calls.Call do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Statements.Statement
  alias Discussit.Conversations.Conversation
  alias Discussit.Participants.Participant
  alias Discussit.Files.File

  @channels [:left, :right]

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "calls" do
    field :external_id, :string
    field :source, Ecto.Enum, values: [:openphone]
    field :answered_at, :naive_datetime_usec
    field :completed_at, :naive_datetime_usec

    field :status, Ecto.Enum,
      values: [
        :created,
        :upload_failed,
        :upload_empty,
        :file_uploaded,
        :transcribing,
        :transcribed,
        :transcription_failed,
        :processed
      ]

    field :from_channel, Ecto.Enum, values: @channels
    field :to_channel, Ecto.Enum, values: @channels

    field :transcript_ids, {:array, :string}

    belongs_to :conversation, Conversation, type: :binary_id
    belongs_to :from_participant, Participant
    belongs_to :to_participant, Participant

    embeds_one :call_recording, File
    embeds_one :voicemail, File

    has_many :statements, Statement

    embeds_many :files, File

    timestamps type: :naive_datetime_usec
  end

  @doc false
  def changeset(call, attrs) do
    call
    |> cast(attrs, [
      :source,
      :external_id,
      :answered_at,
      :completed_at,
      :conversation_id,
      :from_participant_id,
      :from_channel,
      :to_participant_id,
      :to_channel,
      :status,
      :transcript_ids
    ])
    |> cast_embed(:call_recording)
    |> cast_embed(:voicemail)
    |> validate_required([:source, :external_id])
    |> cast_id()
    |> unique_constraint([:id], name: :calls_pkey)
  end

  def update_changeset(call, attrs) do
    call
    |> cast(attrs, [
      :status,
      :transcript_ids
    ])
    |> cast_embed(:call_recording)
    |> cast_embed(:voicemail)
  end

  def id(:openphone, external_id), do: UUID.uuid5(nil, "openphone-" <> external_id)

  defp cast_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        external_id = get_change(changeset, :external_id)
        source = get_change(changeset, :source)

        case {source, external_id} do
          {:openphone, external_id} when is_atom(source) and is_binary(external_id) ->
            put_change(changeset, :id, id(source, external_id))

          _ ->
            add_error(changeset, :id, "insufficient args to generate id")
        end

      _ ->
        changeset
    end
  end

  def cast_openphone_call(
        %Discussit.Events.Openphone.Data.Call{
          id: external_id,
          answered_at: answered_at,
          completed_at: completed_at,
          direction: direction
        },
        %{
          conversation: %{id: conversation_id},
          from_participant: %{id: from_participant_id},
          to_participant: %{id: to_participant_id}
        }
      ) do
    {from_channel, to_channel} =
      case direction do
        "incoming" -> {:right, :left}
        "outgoing" -> {:left, :right}
      end

    %{
      external_id: external_id,
      conversation_id: conversation_id,
      answered_at: answered_at,
      completed_at: completed_at,
      from_participant_id: from_participant_id,
      from_channel: from_channel,
      to_participant_id: to_participant_id,
      to_channel: to_channel,
      source: :openphone,
      status: :created
    }
  end
end
