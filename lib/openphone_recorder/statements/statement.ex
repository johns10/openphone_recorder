defmodule OpenphoneRecorder.Statements.Statement do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Calls.Call
  alias OpenphoneRecorder.StatementSummaries.StatementSummary
  alias OpenphoneRecorder.Participants.Participant

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "statements" do
    field :external_id, :string
    field :source, Ecto.Enum, values: [:openphone, :transcription]
    field :content, :string
    field :occurred_at, :utc_datetime_usec
    field :type, Ecto.Enum, values: [:call, :voicemail, :message]
    field :conversation_id, :binary_id

    belongs_to :participant, Participant
    belongs_to :call, Call, type: :binary_id

    has_many :statement_summaries, StatementSummary
    has_many :summaries, through: [:statement_summaries, :summary]

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(statement, attrs) do
    statement
    |> cast(attrs, [
      :external_id,
      :source,
      :content,
      :occurred_at,
      :type,
      :conversation_id,
      :participant_id,
      :call_id
    ])
    |> validate_required([:occurred_at, :type, :participant_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:call_id)
    |> cast_id()
    |> unique_constraint([:id], name: :statements_pkey)
  end

  defp cast_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        external_id = get_change(changeset, :external_id)
        source = get_change(changeset, :source)

        case {source, external_id} do
          {:openphone, external_id} when is_atom(source) and is_binary(external_id) ->
            put_change(changeset, :id, UUID.uuid5(nil, "openphone-" <> external_id))

          {:transcription, nil} ->
            put_change(changeset, :id, UUID.uuid4())

          _ ->
            add_error(changeset, :id, "insufficient args to generate id")
        end

      _ ->
        changeset
    end
  end

  def cast_openphone_message(
        %OpenphoneRecorder.Events.Openphone.Data.Message{
          id: external_id,
          created_at: occurred_at,
          body: body
        },
        %{
          conversation: %{id: conversation_id},
          from_participant: %{id: participant_id}
        }
      ) do
    %{
      participant_id: participant_id,
      conversation_id: conversation_id,
      external_id: external_id,
      occurred_at: occurred_at,
      source: :openphone,
      type: :message,
      content: body
    }
  end

  def render_for_prompt(%__MODULE__{content: content, participant: participant}),
    do: "#{Participant.render_for_prompt(participant)}: #{content}"
end
