defmodule OpenphoneRecorder.StatementSummariesFixtures do
  import OpenphoneRecorder.StatementsFixtures
  import OpenphoneRecorder.SummariesFixtures

  def statement_summary_fixture(attrs \\ %{}) do
    {:ok, statement_summary} =
      attrs
      |> Enum.into(%{
        statement_id: statement_fixture() |> Map.get(:id),
        summary_id: summary_fixture() |> Map.get(:id)
      })
      |> OpenphoneRecorder.StatementSummaries.create_statement_summary()

    statement_summary
  end
end
