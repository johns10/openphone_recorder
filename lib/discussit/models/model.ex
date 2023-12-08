defmodule Discussit.Models.Model do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Topics.Topic

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "models" do
    field(:merge_object, :string)
    field(:model_object, :string)
    belongs_to(:account, Topic)

    timestamps()
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, [:id, :model_object, :merge_object, :account_id])
    |> foreign_key_constraint(:account_id)
    |> validate_required([:id, :model_object, :merge_object])
  end
end
