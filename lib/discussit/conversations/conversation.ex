defmodule Discussit.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Participants.Participant
  alias Discussit.Accounts.Account
  alias Discussit.Statements.Statement
  alias Discussit.ConversationSummarizers.ConversationSummarizer

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "conversations" do
    field :external_id, :string
    field :source, Ecto.Enum, values: [:openphone, :zoom]
    field :occurred_at, :naive_datetime_usec

    field :last_occurred_at, :naive_datetime_usec, virtual: true

    belongs_to :account, Account, type: :binary_id

    has_many :participants, Participant
    has_many :statements, Statement
    has_many :conversation_summarizers, ConversationSummarizer
    has_many :phone_numbers, through: [:participants, :phone_number]
    has_many :contacts, through: [:phone_numbers, :contact]
    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:source, :external_id, :account_id])
    |> cast_id()
    |> foreign_key_constraint(:account_id)
    |> unique_constraint([:id], name: :conversations_pkey)
    |> validate_required([:source, :account_id])
  end

  defp cast_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        external_id = get_change(changeset, :external_id)
        source = get_change(changeset, :source)

        case {source, external_id} do
          {:openphone, external_id} when is_binary(external_id) ->
            put_change(changeset, :id, UUID.uuid5(nil, "openphone-" <> external_id))

          {:zoom, _} ->
            put_change(changeset, :id, UUID.uuid4())

          _ ->
            add_error(changeset, :id, "insufficient args to generate conversation_id id")
        end

      _ ->
        changeset
    end
  end
end
