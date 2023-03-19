defmodule OpenphoneRecorder.Events.Openphone.Data.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Events.Openphone.Data.Media

  @primary_key false
  embedded_schema do
    field :id, :string
    field :object, :string
    field :from, :string
    field :to, :string
    field :direction, :string
    field :body, :string
    field :status, :string
    field :created_at, :naive_datetime_usec
    field :user_id, :string
    field :phone_number_id, :string
    field :conversation_id, :string

    embeds_many :media, Media
  end

  def changeset(call, params \\ %{}) do
    call
    |> cast(params, [
      :id,
      :object,
      :from,
      :to,
      :direction,
      :body,
      :status,
      :created_at,
      :user_id,
      :phone_number_id,
      :conversation_id
    ])
    |> cast_embed(:media, with: &Media.changeset/2)
  end
end
