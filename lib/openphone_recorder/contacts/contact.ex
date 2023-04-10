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
    |> unique_constraint([:id], name: :contacts_pkey)
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

  def cast_openphone_contact(%OpenphoneRecorder.Events.Openphone.Data.Contact{
        id: external_id,
        name: name,
        phone_numbers: phone_numbers
      }) do
    %{
      phone_numbers:
        Enum.map(phone_numbers, &%{source: :openphone, phone_number: &1.phone_number}),
      external_id: external_id,
      source: :openphone,
      full_name: name
    }
  end
end
