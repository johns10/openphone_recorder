defmodule OpenphoneRecorder.Events.Openphone.Data.Call do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Events.Openphone.Data.Media

  @primary_key false
  embedded_schema do
    field :id, :string
    field :from, :string
    field :to, :string
    field :direction, :string
    field :status, :string
    field :created_at, :naive_datetime_usec
    field :answered_at, :naive_datetime_usec
    field :completed_at, :naive_datetime_usec
    field :user_id, :string
    field :phone_number_id, :string
    field :conversation_id, :string

    embeds_many :media, Media
    embeds_one :voicemail, Media
  end

  def changeset(call, attrs) do
    call
    |> cast(attrs, [
      :id,
      :from,
      :to,
      :direction,
      :status,
      :created_at,
      :answered_at,
      :completed_at,
      :user_id,
      :phone_number_id,
      :conversation_id
    ])
    |> cast_embed(:voicemail, with: &Media.changeset/2)
    |> cast_embed(:media, with: &Media.changeset/2)
    |> validate_required([
      :id,
      :from,
      :to,
      :direction,
      :status,
      :created_at,
      :user_id,
      :phone_number_id,
      :conversation_id
    ])
  end
end
