defmodule OpenphoneRecorder.Conversations.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "conversations" do
    field :external_id, :string
    field :source, Ecto.Enum, values: [:openphone]
    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:source, :external_id])
    |> cast_id()
    |> validate_required([:source, :external_id])
  end

  defp cast_id(changeset) do
    external_id = get_change(changeset, :external_id)
    source = get_change(changeset, :source)

    case {source, external_id} do
      {:openphone, external_id} when is_atom(source) and is_binary(external_id) ->
        put_change(changeset, :id, UUID.uuid5(nil, "openphone-" <> external_id))

      _ ->
        add_error(changeset, :id, "insufficient args to generate id")
    end
  end
end
