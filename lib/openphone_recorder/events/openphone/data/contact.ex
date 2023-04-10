defmodule OpenphoneRecorder.Events.Openphone.Data.Contact do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Events.Openphone.Data.Field

  @primary_key false
  embedded_schema do
    field :id, :string
    field :first_name, :string
    field :last_name, :string
    field :company, :string
    field :role, :string

    embeds_many :fields, Field
  end

  def changeset(voicemail, attrs) do
    voicemail
    |> cast(attrs, [:id, :first_name, :last_name, :company, :role])
    |> cast_embed(:fields, with: &Field.changeset/2)
  end
end
