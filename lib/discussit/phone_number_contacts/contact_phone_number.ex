defmodule Discussit.ContactPhoneNumbers.ContactPhoneNumber do
  alias Discussit.PhoneNumbers.PhoneNumber
  alias Discussit.Contacts.Contact
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_phone_numbers" do
    belongs_to :phone_number, PhoneNumber, type: :binary_id
    belongs_to :contact, Contact, type: :binary_id

    field :temp_id, :string, virtual: true
    field :delete, :boolean, virtual: true

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(contact_phone_number, attrs) do
    contact_phone_number
    |> Map.put(:temp_id, contact_phone_number.temp_id || attrs["temp_id"])
    |> cast(attrs, [:phone_number_id, :contact_id, :delete])
    |> cast_assoc(:phone_number)
    |> foreign_key_constraint(:phone_number_id)
    |> foreign_key_constraint(:contact_id)
    |> unique_constraint([:contact_id, :phone_number_id])
    |> validate_required([])
    |> maybe_mark_for_deletion()
  end

  defp maybe_mark_for_deletion(%{data: %{id: nil}} = changeset), do: changeset

  defp maybe_mark_for_deletion(changeset) do
    if get_change(changeset, :delete) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
