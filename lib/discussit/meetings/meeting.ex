defmodule Discussit.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Files.File
  alias Discussit.Users.User

  @derive {Jason.Encoder, only: [:id, :name, :occurred_at, :provider, :upload_status, :projector_status, :files]}
  schema "meetings" do
    field :name, :string
    field :occurred_at, :naive_datetime_usec
    field :provider, Ecto.Enum, values: [:zoom, :teams]
    field :upload_status, Ecto.Enum, values: [:created, :files_uploading, :files_uploaded]
    field :projector_status, Ecto.Enum, values: [:not_started, :in_progress, :done]

    embeds_many :files, File

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [:provider, :occurred_at, :name, :upload_status, :projector_status, :user_id])
    |> cast_embed(:files)
    |> foreign_key_constraint(:user_id)
    |> validate_required([:provider, :occurred_at])
    |> unique_constraint([:name, :occurred_at, :user_id])
  end
end
