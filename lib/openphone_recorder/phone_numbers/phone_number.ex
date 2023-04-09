defmodule OpenphoneRecorder.PhoneNumbers.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Contacts.Contact

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "phone_numbers" do
    field :external_id, :string
    field :phone_number, EctoPhoneNumber
    field :source, Ecto.Enum, values: [:openphone]

    belongs_to :contact, Contact, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(phone_number, attrs) do
    phone_number
    |> cast(attrs, [:external_id, :contact_id, :phone_number, :source])
    |> cast_id()
    |> validate_required([:phone_number, :source])
    |> foreign_key_constraint(:contact_id)
    |> unique_constraint([:id], name: :phone_numbers_pkey)
  end

  def id(phone_number), do: UUID.uuid5(nil, to_string(phone_number))

  defp cast_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        case get_change(changeset, :phone_number) do
          nil ->
            changeset

          phone_number ->
            put_change(changeset, :id, id(phone_number))
        end

      _ ->
        changeset
    end
  end
end
