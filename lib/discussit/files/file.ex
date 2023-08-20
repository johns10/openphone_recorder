defmodule Discussit.Files.File do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :bucket, :string
    field :key, :string
    field :metadata, :map
  end

  def changeset(object \\ %__MODULE__{}, attrs) do
    object
    |> cast(attrs, [:bucket, :key, :metadata])
    |> validate_required([:bucket, :key, :metadata])
  end
end
