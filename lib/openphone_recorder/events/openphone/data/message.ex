defmodule OpenphoneRecorder.Events.Openphone.Data.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Events.Openphone.Data.Media

  @primary_key false
  embedded_schema do
    field :id, :string
    field :external_id, :string
    field :source, Ecto.Enum, values: [:openphone]
    field :object, :string
    field :from, :string
    field :to, :string
    field :direction, :string
    field :body, :string
    field :status, :string
    field :created_at, :naive_datetime_usec
    field :user_id, :string
    field :phone_number_id, :string
    field :conversation_id, :string

    embeds_many :media, Media
  end

  def changeset(call, params \\ %{}) do
    call
    |> cast(params, [
      :id,
      :object,
      :from,
      :to,
      :direction,
      :body,
      :status,
      :created_at,
      :user_id,
      :phone_number_id,
      :conversation_id
    ])
    |> cast_id()
    |> cast_embed(:media, with: &Media.changeset/2)
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
