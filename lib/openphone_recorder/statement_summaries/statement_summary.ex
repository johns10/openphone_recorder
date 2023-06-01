defmodule OpenphoneRecorder.StatementSummaries.StatementSummary do
  use Ecto.Schema
  import Ecto.Changeset
  alias OpenphoneRecorder.Statements.Statement
  alias OpenphoneRecorder.Summaries.Summary

  schema "statement_summaries" do
    belongs_to :statement, Statement, type: :binary_id
    belongs_to :summary, Summary, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(statement_summary, attrs) do
    statement_summary
    |> cast(attrs, [:statement_id, :summary_id])
    |> validate_required([])
    |> foreign_key_constraint(:summary_id)
    |> foreign_key_constraint(:statement_id)
  end
end
