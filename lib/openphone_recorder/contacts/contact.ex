defmodule OpenphoneRecorder.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.PhoneNumbers.PhoneNumber

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "contacts" do
    field :external_id, :string
    field :first_name, :string
    field :last_name, :string
    field :company, :string
    field :role, :string
    field :source, Ecto.Enum, values: [:openphone, :user]

    has_many :phone_numbers, PhoneNumber

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
    phone_numbers =
      fields
      |> Enum.filter(&(&1.type == :phone_number))
      |> Enum.map(&%{source: :openphone, phone_number: &1.value})

    %{
      phone_numbers: phone_numbers,
      external_id: external_id,
      source: :openphone,
      first_name: first_name,
      last_name: last_name
    }
  end
end
