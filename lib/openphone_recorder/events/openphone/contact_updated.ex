defmodule OpenphoneRecorder.Events.Openphone.ContactUpdated do
  use Ecto.Schema
  alias OpenphoneRecorder.Events.Openphone.Data.Contact

  @primary_key false
  embedded_schema do
    field :id, :string
    field :object, :string
    field :api_version, :string
    field :created_at, :utc_datetime_usec
    embeds_one :data, Contact
  end
end
