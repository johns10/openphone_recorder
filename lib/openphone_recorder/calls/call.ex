defmodule OpenphoneRecorder.Calls.Call do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "calls" do
    field :external_id, :string
    field :source, Ecto.Enum, values: [:openphone]
    field :answered_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :conversation_id, :id

    timestamps()
  end

  @doc false
  def changeset(call, attrs) do
    call
    |> cast(attrs, [:source, :external_id])
    |> validate_required([:source, :external_id])
    |> cast_id()
    |> unique_constraint([:id], name: :calls_pkey)
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

  def cast_openphone_call(%OpenphoneRecorder.Events.Openphone.Data.Call{
        id: external_id,
        answered_at: answered_at,
        completed_at: completed_at
      }) do
    %{
      external_id: external_id,
      answered_at: answered_at,
      completed_at: completed_at,
      source: :openphone
    }
  end
end
