defmodule OpenphoneRecorder.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.PhoneNumbers.PhoneNumber

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "contacts" do
    field :external_id, :string
    field :full_name, :string
    field :source, Ecto.Enum, values: [:openphone, :user]

    has_many :phone_numbers, PhoneNumber

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:full_name, :external_id, :source])
    |> cast_id()
    |> validate_required([:full_name, :source])
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
            put_change(changeset, :id, UUID.uuid4())
        end

      _ ->
        changeset
    end
  end
end
