defmodule OpenphoneRecorder.Summaries.Summary do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.ConversationSummarizers.ConversationSummarizer
  alias OpenphoneRecorder.StatementSummaries.StatementSummary
  alias PgRanges.TsRange

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "summaries" do
    field :title, :string
    field :content, :string
    field :params, :map
    field :summary_id, :id
    field :level, :integer
    field :tsrange, TsRange

    belongs_to :conversation_summarizer, ConversationSummarizer
    has_many :statement_summaries, StatementSummary

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(summary, attrs) do
    summary
    |> cast(attrs, [:title, :content, :params, :conversation_summarizer_id, :tsrange])
    |> validate_required([:content])
    |> foreign_key_constraint(:summarizer_id)
  end
end
