defmodule OpenphoneRecorder.SummariesTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.Summaries

  describe "summaries" do
    alias OpenphoneRecorder.Summaries.Summary

    import OpenphoneRecorder.SummariesFixtures

    @invalid_attrs %{content: nil, params: nil}

    test "list_summaries/0 returns all summaries" do
      summary = summary_fixture()
      assert Summaries.list_summaries() == [summary]
    end

    test "list_summaries/1 returns summaries before date" do
      old_summary = summary_fixture(%{to: DateTime.utc_now() |> DateTime.add(-10000)})
      new_summary = summary_fixture(%{to: DateTime.utc_now() |> DateTime.add(10000)})
      assert Summaries.list_summaries(filters: [before: DateTime.utc_now()]) == [old_summary]
    end

    test "get_summary!/1 returns the summary with given id" do
      summary = summary_fixture()
      assert Summaries.get_summary!(summary.id) == summary
    end

    test "create_summary/1 with valid data creates a summary" do
      valid_attrs = %{content: "some content", params: %{}}

      assert {:ok, %Summary{} = summary} = Summaries.create_summary(valid_attrs)
      assert summary.content == "some content"
      assert summary.params == %{}
    end

    test "create_summary/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Summaries.create_summary(@invalid_attrs)
    end

    test "update_summary/2 with valid data updates the summary" do
      summary = summary_fixture()
      update_attrs = %{content: "some updated content", params: %{}}

      assert {:ok, %Summary{} = summary} = Summaries.update_summary(summary, update_attrs)
      assert summary.content == "some updated content"
      assert summary.params == %{}
    end

    test "update_summary/2 with invalid data returns error changeset" do
      summary = summary_fixture()
      assert {:error, %Ecto.Changeset{}} = Summaries.update_summary(summary, @invalid_attrs)
      assert summary == Summaries.get_summary!(summary.id)
    end

    test "delete_summary/1 deletes the summary" do
      summary = summary_fixture()
      assert {:ok, %Summary{}} = Summaries.delete_summary(summary)
      assert_raise Ecto.NoResultsError, fn -> Summaries.get_summary!(summary.id) end
    end

    test "change_summary/1 returns a summary changeset" do
      summary = summary_fixture()
      assert %Ecto.Changeset{} = Summaries.change_summary(summary)
    end
  end
end
