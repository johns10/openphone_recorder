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
    field :summary_id, :id
    field :level, :integer
    field :from, :utc_datetime_usec
    field :to, :utc_datetime_usec

    belongs_to :summarizer, Summarizer
    has_many :statement_summaries, StatementSummary

    timestamps()
  end

  @doc false
  def changeset(summary, attrs) do
    summary
    |> cast(attrs, [:title, :content, :params, :summarizer_id, :from, :to])
    |> validate_required([:content])
    |> foreign_key_constraint(:summarizer_id)
  end
end
