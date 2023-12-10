defmodule DiscussitWeb.TopicLive.TrainingForm do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :statements_count, :integer
    field :model_id, :binary_id
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:model_id, :statements_count])
    |> validate_required([:model_id, :statements_count])
    |> validate_number(:statements_count, greater_than: 1000)
  end
end
