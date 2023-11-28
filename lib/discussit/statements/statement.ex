defmodule Discussit.Statements.Statement do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Conversations.Conversation
  alias Discussit.Meetings.Meeting
  alias Discussit.Calls.Call
  alias Discussit.StatementSummaries.StatementSummary
  alias Discussit.Participants.Participant
  alias Discussit.Embeddings.Embedding
  alias Discussit.Topics.Topic
  alias PgRanges.TsRange

  @derive {Jason.Encoder,
           only: [
             :id,
             :external_id,
             :source,
             :content,
             :occurred_at,
             :type,
             :ts_range,
             :all_stopwords,
             :unprocessable,
             :embedding,
             :labelled_topic
           ]}
  @primary_key {:id, :binary_id, autogenerate: false}
  schema "statements" do
    field :external_id, :string
    field :source, Ecto.Enum, values: [:openphone, :transcription, :zoom]
    field :content, :string
    field :occurred_at, :naive_datetime_usec
    field :type, Ecto.Enum, values: [:call, :voicemail, :message, :meeting]
    field :ts_range, TsRange
    field :all_stopwords, :boolean
    field :unprocessable, :boolean
    field :representative, :boolean

    belongs_to :participant, Participant
    belongs_to :call, Call, type: :binary_id
    belongs_to :meeting, Meeting
    belongs_to :conversation, Conversation, type: :binary_id
    belongs_to :topic, Topic
    belongs_to :model_topic, Topic
    belongs_to :labelled_topic, Topic

    has_one :embedding, Embedding

    has_many :statement_summaries, StatementSummary
    has_many :summaries, through: [:statement_summaries, :summary]

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(statement, attrs) do
    statement
    |> cast(attrs, [
      :external_id,
      :conversation_id,
      :participant_id,
      :meeting_id,
      :topic_id,
      :source,
      :content,
      :occurred_at,
      :type,
      :call_id,
      :ts_range,
      :all_stopwords,
      :unprocessable,
      :model_topic_id,
      :labelled_topic_id,
      :representative
    ])
    |> validate_required([:occurred_at, :type])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:call_id)
    |> foreign_key_constraint(:meeting_id)
    |> foreign_key_constraint(:topic_id)
    |> foreign_key_constraint(:model_topic_id)
    |> foreign_key_constraint(:labelled_topic_id)
    |> cast_id()
    |> unique_constraint([:id], name: :statements_pkey)
  end

  defp cast_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        external_id = get_change(changeset, :external_id)
        source = get_change(changeset, :source)

        case {source, external_id} do
          {source, external_id} when is_atom(source) and is_binary(external_id) ->
            put_change(
              changeset,
              :id,
              UUID.uuid5(nil, Atom.to_string(source) <> "-" <> external_id)
            )

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
        %Discussit.Events.Openphone.Data.Message{
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
    do: ~s(#{Participant.render_for_prompt(participant)}: #{content}\n)
end
