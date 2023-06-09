defmodule OpenphoneRecorder.Summaries.Summary do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Summarizers.Summarizer

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "summaries" do
    field :title, :string
    field :content, :string
    field :params, :map
    field :type, Ecto.Enum, values: [:temporal, :topical]
    field :summary_id, :id
    field :level, :integer

    belongs_to :summarizer, Summarizer

    timestamps()
  end

  @doc false
  def changeset(summary, attrs) do
    summary
    |> cast(attrs, [:title, :content, :type, :params, :summarizer_id])
    |> validate_required([:content, :type])
    |> foreign_key_constraint(:summarizer_id)
  end
end
