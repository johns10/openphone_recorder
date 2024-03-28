defmodule Discussit.Models.Model do
  @moduledoc """
  The `Model` struct tracks machine learning models in Discussit.
  It's set up to allow model versioning.
  In the case of topic analysis models, we are using a merge strategy to iteratively train models.
  That means that for each version, we will have an entirely new model, which will be stored in the merge_model S3 object.
  The current version of the model will be kept in an S3 object defined in `model_object`.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Accounts.Account

  def default_llm_id(), do: "gpt-3.5-turbo"

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "models" do
    field :name, :string
    field :external_id, :string
    field :type, Ecto.Enum, values: [:llm, :topic]
    field :merge_object, :string
    field :model_object, :string
    belongs_to :account, Account

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(model, attrs) do
    model
    |> cast(attrs, [:id, :name, :external_id, :type, :model_object, :merge_object, :account_id])
    |> foreign_key_constraint(:account_id)
    |> validate_required([:id])
  end
end
