defmodule OpenphoneRecorder.PhoneNumbers.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "phone_numbers" do
    field :external_id, :string
    field :phone_number, EctoPhoneNumber
    field :source, Ecto.Enum, values: [:openphone]

    timestamps()
  end

  @doc false
  def changeset(phone_number, attrs) do
    phone_number
    |> cast(attrs, [:external_id, :phone_number, :source])
    |> cast_id()
    |> validate_required([:external_id, :phone_number, :source])
  end

  defp cast_id(changeset) do
    case get_field(changeset, :id) do
      nil ->
        case get_change(changeset, :phone_number) do
          nil ->
            changeset

          phone_number ->
            put_change(changeset, :id, UUID.uuid5(nil, to_string(phone_number)))
        end

      _ ->
        changeset
    end
  end
end
