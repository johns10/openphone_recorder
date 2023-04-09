defmodule OpenphoneRecorder.Events.Openphone.Data.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Events.Openphone.Data.PhoneNumber

  @primary_key false
  embedded_schema do
    field :id, :string
    field :name, :string
    field :created_at, :utc_datetime_usec

    embeds_many :phone_numbers, PhoneNumber
  end

  def changeset(voicemail, attrs) do
    voicemail
    |> cast(attrs, [:id, :name, :created_at])
    |> cast_embed(:phone_numbers, with: &PhoneNumber.changeset/2)
  end
end
