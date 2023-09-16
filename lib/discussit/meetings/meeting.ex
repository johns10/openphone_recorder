defmodule Discussit.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Participants.Participant
  alias Discussit.Statements.Statement
  alias Discussit.Files.File
  alias Discussit.Users.User
  alias Discussit.Accounts.Account
  alias Discussit.Conversations.Conversation

  @derive {Jason.Encoder,
           only: [:id, :name, :occurred_at, :source, :upload_status, :projector_status, :files]}
  schema "meetings" do
    field :name, :string
    field :occurred_at, :naive_datetime_usec
    field :source, Ecto.Enum, values: [:zoom, :teams]
    field :upload_status, Ecto.Enum, values: [:created, :files_uploading, :files_uploaded]
    field :projector_status, Ecto.Enum, values: [:not_started, :in_progress, :done]
    field :external_id, :string
    field :transcript_id, :string
    field :segments, {:array, :map}

    embeds_many :files, File

    belongs_to :user, User
    belongs_to :account, Account
    belongs_to :conversation, Conversation, type: :binary_id

    has_many :statements, Statement
    has_many :participants, Participant

    timestamps()
  end

  @doc false
  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [
      :source,
      :occurred_at,
      :name,
      :upload_status,
      :projector_status,
      :user_id,
      :external_id,
      :segments,
      :conversation_id,
      :transcript_id
    ])
    |> cast_embed(:files)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:conversation_id)
    |> validate_required([:source, :occurred_at])
    |> unique_constraint([:name, :occurred_at, :user_id])
  end
end
