defmodule Discussit.StatementSummariesTest do
  use Discussit.DataCase

  alias Discussit.StatementSummaries

  describe "statement_summaries" do
    alias Discussit.StatementSummaries.StatementSummary

    import Discussit.StatementSummariesFixtures

    @invalid_attrs %{participant_id: Ecto.UUID.generate(), summary_id: Ecto.UUID.generate()}

    test "list_statement_summaries/0 returns all statement_summaries" do
      statement_summary = statement_summary_fixture()
      assert StatementSummaries.list_statement_summaries() == [statement_summary]
    end

    test "get_statement_summary!/1 returns the statement_summary with given id" do
      statement_summary = statement_summary_fixture()
      assert StatementSummaries.get_statement_summary!(statement_summary.id) == statement_summary
    end

    test "create_statement_summary/1 with valid data creates a statement_summary" do
      valid_attrs = %{}

      assert {:ok, %StatementSummary{} = _statement_summary} =
               StatementSummaries.create_statement_summary(valid_attrs)
    end

    test "create_statement_summary/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               StatementSummaries.create_statement_summary(@invalid_attrs)
    end

    test "update_statement_summary/2 with valid data updates the statement_summary" do
      statement_summary = statement_summary_fixture()
      update_attrs = %{}

      assert {:ok, %StatementSummary{} = _statement_summary} =
               StatementSummaries.update_statement_summary(statement_summary, update_attrs)
    end

    test "update_statement_summary/2 with invalid data returns error changeset" do
      statement_summary = statement_summary_fixture()

      assert {:error, %Ecto.Changeset{}} =
               StatementSummaries.update_statement_summary(statement_summary, @invalid_attrs)

      assert statement_summary == StatementSummaries.get_statement_summary!(statement_summary.id)
    end

    test "delete_statement_summary/1 deletes the statement_summary" do
      statement_summary = statement_summary_fixture()

      assert {:ok, %StatementSummary{}} =
               StatementSummaries.delete_statement_summary(statement_summary)

      assert_raise Ecto.NoResultsError, fn ->
        StatementSummaries.get_statement_summary!(statement_summary.id)
      end
    end

    test "change_statement_summary/1 returns a statement_summary changeset" do
      statement_summary = statement_summary_fixture()
      assert %Ecto.Changeset{} = StatementSummaries.change_statement_summary(statement_summary)
    end
  end
end
