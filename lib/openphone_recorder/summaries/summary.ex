defmodule OpenphoneRecorder.Summaries.Summary do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Summarizers.Summarizer
  alias OpenphoneRecorder.StatementSummaries.StatementSummary

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "summaries" do
    field :title, :string
    field :content, :string
    field :params, :map
    field :chunker, Ecto.Enum, values: [:temporal, :topical]
    field :summary_id, :id
    field :level, :integer

    belongs_to :summarizer, Summarizer
    has_many :statement_summaries, StatementSummary

    timestamps()
  end

  @doc false
  def changeset(summary, attrs) do
    summary
    |> cast(attrs, [:title, :content, :chunker, :params, :summarizer_id])
    |> validate_required([:content, :chunker])
    |> foreign_key_constraint(:summarizer_id)
  end
end
