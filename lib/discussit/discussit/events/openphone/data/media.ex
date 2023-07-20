defmodule Discussit.Events.Openphone.Data.Media do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :url, :string
    field :type, :string
    field :duration, :integer
  end

  def changeset(voicemail, attrs) do
    voicemail
    |> cast(attrs, [:url, :type, :duration])
    |> validate_required([:url, :type])
  end
end
