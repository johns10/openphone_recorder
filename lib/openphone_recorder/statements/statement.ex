defmodule OpenphoneRecorder.Statements.Statement do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Calls.Call

  schema "statements" do
    field :content, :string
    field :occurred_at, :utc_datetime
    field :type, Ecto.Enum, values: [:call, :voicemail, :message]
    field :conversation_id, :binary_id
    field :participant_id, :id

    belongs_to :call, Call, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(statement, attrs) do
    statement
    |> cast(attrs, [:content, :occurred_at, :type, :conversation_id, :participant_id, :call_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:participant_id)
    |> foreign_key_constraint(:call_id)
    |> validate_required([:content, :occurred_at, :type])
  end

  def cast_openphone_message(
        %OpenphoneRecorder.Events.Openphone.Data.Message{
          id: external_id,
          created_at: occurred_at,
          body: body
        },
        conversation_id
      ) do
    %{
      conversation_id: conversation_id,
      external_id: external_id,
      occurred_at: occurred_at,
      source: :openphone,
      type: :message,
      content: body
    }
  end
end
