defmodule Discussit.PhoneNumbers.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset
  import Discussit.PhoneNumbers.AdditionalValidation
  alias Discussit.ContactPhoneNumbers.ContactPhoneNumber
  alias Discussit.Contacts.Contact

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "phone_numbers" do
    field(:external_id, :string)
    field(:value, EctoPhoneNumber)
    field(:source, Ecto.Enum, values: [:openphone, :user])

    has_many(:contact_phone_numbers, ContactPhoneNumber)
    has_many(:contacts, through: [:contact_phone_numbers, :contact])

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(phone_number, attrs) do
    phone_number
    |> cast(attrs, [:external_id, :value, :source])
    |> cast_id()
    |> handle_shortcode(attrs)
    |> handle_no_caller_id(attrs)
    |> validate_required([:value, :source])
    |> unique_constraint([:id], name: :phone_numbers_pkey)
  end

  def id(phone_number), do: UUID.uuid5(nil, to_string(phone_number))

  def cast_id(changeset) do
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

  def render_for_prompt(%__MODULE__{contacts: [contact]}), do: Contact.render_for_prompt(contact)

  def render_for_prompt(%__MODULE__{contacts: [contact | _]}),
    do: Contact.render_for_prompt(contact)

  def render_for_prompt(%__MODULE__{contacts: [], value: value}), do: "#{value}"
  def render_for_prompt(%__MODULE__{value: value}), do: "#{value}"
end
