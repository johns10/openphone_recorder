defmodule OpenphoneRecorder.Summaries.Summary do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "summaries" do
    field(:content, :string)
    field(:params, :map)
    field(:type, Ecto.Enum, values: [:temporal, :topical])
    field(:summary_id, :id)
    field(:level, :integer)

    timestamps()
  end

  @doc false
  def changeset(summary, attrs) do
    summary
    |> cast(attrs, [:content, :type, :params])
    |> validate_required([:content, :type, :params])
  end
end
