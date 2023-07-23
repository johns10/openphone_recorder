defmodule Discussit.PhoneNumbers.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.ContactPhoneNumbers.ContactPhoneNumber
  alias Discussit.Contacts.Contact

  @shortcode_regexes [
    ~r/[1-9]\\d{2,5}/,
    ~r/11(?:2|5[1-47]|[68]\d|7[0-57]|98)|[2-9]\d{3,5}|[2-8]11|9(?:11|33|88)/,
    ~r/112|611|9(?:11|33|88)/,
    ~r/2(?:3333|(?:4224|7562|900)2|56447|6688)|3(?:1010|2665|7404)|40404|560560|6(?:0060|22639|5246|7622)|7(?:0701|3822|4666)|8(?:(?:3825|7226)5|4816)|99099/,
    ~r/24280|(?:381|968)35|4(?:3355|7553|8221)|5(?:(?:489|934)2|5928)|72078|(?:323|960)40|(?:276|414)63|(?:2(?:520|744)|7390|9968)9|(?:693|732|976)88|(?:3(?:556|825)|5294|8623|9729)4|(?:3378|4136|7642|8961|9979)6|(?:4(?:6(?:15|32)|827)|(?:591|720)8|9529)7/,
    ~r/336\d\d|[2-9]\d{3}|[2356]11/,
    ~r/112|911/,
    ~r/9(?:33|88)/,
    ~r/1(?:0[4-9]|1[2368]|2[0-3568]|787)|911/,
    ~r/128|911/
  ]

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "phone_numbers" do
    field(:external_id, :string)
    field(:value, EctoPhoneNumber)
    field(:source, Ecto.Enum, values: [:openphone])

    belongs_to(:contact, Contact, type: :binary_id)
    has_many(:contact_phone_numbers, ContactPhoneNumber)
    has_many(:contacts, through: [:contact_phone_numbers, :contact])

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(phone_number, attrs) do
    phone_number
    |> cast(attrs, [:external_id, :value, :source, :contact_id])
    |> cast_id()
    |> handle_shortcode(attrs)
    |> validate_required([:source])
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

  defp handle_shortcode(%{errors: errors} = changeset, attrs) do
    Keyword.get(errors, :value)
    |> case do
      nil ->
        changeset

      {"is invalid", [type: EctoPhoneNumber, validation: :cast]} ->
        key = if Enum.at(attrs, 0) |> elem(0) |> is_atom(), do: :value, else: "value"
        invalid_value = Map.get(attrs, key)

        case is_shortcode?(invalid_value) && String.length(invalid_value) in [5, 6] do
          true ->
            changeset.data
            |> cast(attrs, [:external_id, :source, :contact_id])
            |> put_change(:value, %EctoPhoneNumber{
              e164: String.to_integer(invalid_value)
            })
            |> cast_id()
            |> handle_shortcode(attrs)
            |> validate_required([:source])
            |> foreign_key_constraint(:contact_id)
            |> unique_constraint([:id], name: :phone_numbers_pkey)

          false ->
            changeset
        end
    end
  end

  defp is_shortcode?(phone_number_value) do
    @shortcode_regexes
    |> Enum.any?(fn regex ->
      Regex.match?(regex, phone_number_value)
    end)
  end

  def render_for_prompt(%__MODULE__{contact: nil, value: value}), do: "#{value}"
  def render_for_prompt(%__MODULE__{contact: contact}), do: Contact.render_for_prompt(contact)
end
