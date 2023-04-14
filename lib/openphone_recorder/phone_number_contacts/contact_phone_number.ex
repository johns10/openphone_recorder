defmodule OpenphoneRecorder.ContactPhoneNumbers.ContactPhoneNumber do
  alias OpenphoneRecorder.PhoneNumbers.PhoneNumber
  alias OpenphoneRecorder.Contacts.Contact
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_phone_numbers" do
    belongs_to :phone_number, PhoneNumber, type: :binary_id
    belongs_to :contact, Contact, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(contact_phone_number, attrs) do
    contact_phone_number
    |> cast(attrs, [:phone_number_id, :contact_id])
    |> foreign_key_constraint(:phone_number_id)
    |> foreign_key_constraint(:contact_id)
    |> unique_constraint([:contact_id, :phone_number_id])
    |> validate_required([])
  end
end
