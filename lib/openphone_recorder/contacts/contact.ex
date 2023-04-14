defmodule OpenphoneRecorder.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.ContactPhoneNumbers.ContactPhoneNumber

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "contacts" do
    field :external_id, :string
    field :first_name, :string
    field :last_name, :string
    field :company, :string
    field :role, :string
    field :source, Ecto.Enum, values: [:openphone, :user]

    has_many :contact_phone_numbers, ContactPhoneNumber
    has_many :phone_numbers, through: [:contact_phone_numbers, :phone_number]

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:first_name, :last_name, :company, :role, :external_id, :source])
    |> cast_id()
    |> validate_required([:source])
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
        first_name: first_name,
        last_name: last_name,
        fields: fields
      }) do
    phone_numbers = cast_phone_numbers(fields["phone"])

    %{
      phone_numbers: phone_numbers,
      external_id: external_id,
      source: :openphone,
      first_name: first_name,
      last_name: last_name
    }
  end

  defp cast_phone_numbers(phone_number) when is_binary(phone_number),
    do: [cast_phone_number(phone_number)]

  defp cast_phone_numbers(phone_numbers) when is_list(phone_numbers),
    do: Enum.map(phone_numbers, &cast_phone_number/1)

  defp cast_phone_number(phone_number), do: %{phone_number: phone_number, source: :openphone}
end
