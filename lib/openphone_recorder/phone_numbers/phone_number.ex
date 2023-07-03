defmodule OpenphoneRecorder.PhoneNumbers.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.ContactPhoneNumbers.ContactPhoneNumber
  alias OpenphoneRecorder.Contacts.Contact

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "phone_numbers" do
    field :external_id, :string
    field :value, EctoPhoneNumber
    field :source, Ecto.Enum, values: [:openphone]

    belongs_to :contact, Contact, type: :binary_id
    has_many :contact_phone_numbers, ContactPhoneNumber
    has_many :contacts, through: [:contact_phone_numbers, :contact]

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(phone_number, attrs) do
    phone_number
    |> cast(attrs, [:external_id, :value, :source, :contact_id])
    |> cast_id()
    |> validate_required([:value, :source])
    |> foreign_key_constraint(:contact_id)
    |> unique_constraint([:id], name: :phone_numbers_pkey)
  end

  def id(phone_number), do: UUID.uuid5(nil, to_string(phone_number))

  defp cast_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        case get_change(changeset, :value) do
          nil ->
            changeset

          phone_number ->
            put_change(changeset, :id, id(phone_number))
        end

      _ ->
        changeset
    end
  end

  def render_for_prompt(%__MODULE__{contact: nil, value: value}), do: "#{value}"
  def render_for_prompt(%__MODULE__{contact: contact}), do: Contact.render_for_prompt(contact)
end
