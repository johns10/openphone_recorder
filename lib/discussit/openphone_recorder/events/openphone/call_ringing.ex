defmodule Discussit.Events.Openphone.CallRinging do
  use Ecto.Schema
  alias Discussit.Events.Openphone.Data.Call

  @primary_key false
  embedded_schema do
    field :id, :string
    field :object, :string
    field :api_version, :string
    field :created_at, :naive_datetime_usec
    embeds_one :data, Call
  end
end
