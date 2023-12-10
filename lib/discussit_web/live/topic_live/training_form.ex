defmodule DiscussitWeb.TopicLive.TrainingForm do
  use Ecto.Schema
  import Ecto.Changeset

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :statements_count, :integer
    field :model_id, :binary_id
    field :account_id, :binary_id
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:statements_count])
    |> validate_required([:statements_count])
    |> validate_number(:statements_count, greater_than: 1000)
  end
end
