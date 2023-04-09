defmodule OpenphoneRecorder.Events.Openphone.CallRecordingCompleted do
  use Ecto.Schema
  alias OpenphoneRecorder.Events.Openphone.Data.Call

  @primary_key false
  embedded_schema do
    field :id, :string
    field :object, :string
    field :api_version, :string
    field :created_at, :utc_datetime_usec
    embeds_one :data, Call
  end
end
