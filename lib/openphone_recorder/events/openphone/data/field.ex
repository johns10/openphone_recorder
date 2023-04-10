defmodule OpenphoneRecorder.Events.Openphone.Data.Field do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :type, Ecto.Enum, values: [:email, :"phone-number", :phone_number, :string]
    field :value, :string
  end

  def changeset(voicemail, attrs) do
    voicemail
    |> cast(attrs, [:name, :type, :value])
    |> cast_type()
    |> validate_required([:name, :type])
  end

  def cast_type(changeset) do
    changeset
    |> get_change(:type)
    |> case do
      :"phone-number" -> put_change(changeset, :type, :phone_number)
      _ -> changeset
    end
  end
end
