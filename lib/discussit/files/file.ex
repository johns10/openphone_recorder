defmodule Discussit.Files.File do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:bucket, :key, :metadata, :url]}
  embedded_schema do
    field :bucket, :string
    field :key, :string
    field :metadata, :map
    field :url, :string, virtual: true
  end

  def changeset(object \\ %__MODULE__{}, attrs) do
    object
    |> cast(attrs, [:bucket, :key, :metadata, :url])
    |> validate_required([:bucket, :key, :metadata])
  end
end
