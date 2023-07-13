defmodule Discussit.SummariesTest do
  use Discussit.DataCase

  alias Discussit.Summaries

  describe "summaries" do
    alias Discussit.Summaries.Summary

    import Discussit.SummariesFixtures

    @invalid_attrs %{content: nil, params: nil}

    test "list_summaries/0 returns all summaries" do
      summary = summary_fixture()
      assert Summaries.list_summaries() == [summary]
    end

    test "list_summaries/1 returns summaries ordered by tsrange" do
      range_1 =
        PgRanges.TsRange.new(
          NaiveDateTime.utc_now() |> NaiveDateTime.add(-5),
          NaiveDateTime.utc_now() |> NaiveDateTime.add(-3)
        )

      range_2 =
        PgRanges.TsRange.new(
          NaiveDateTime.utc_now() |> NaiveDateTime.add(-2),
          NaiveDateTime.utc_now() |> NaiveDateTime.add(-1)
        )

      sum_1 = summary_fixture(%{summary_interval: range_1})
      sum_2 = summary_fixture(%{summary_interval: range_2})

      assert Summaries.list_summaries(order_by: [summary_interval_lower: :desc]) == [sum_2, sum_1]
    end

    test "list_summaries/1 returns summaries before date" do
      old_range =
        PgRanges.TsRange.new(
          NaiveDateTime.utc_now() |> NaiveDateTime.add(-20000),
          NaiveDateTime.utc_now() |> NaiveDateTime.add(-10000)
        )

      future_range =
        PgRanges.TsRange.new(
          NaiveDateTime.utc_now() |> NaiveDateTime.add(10000),
          NaiveDateTime.utc_now() |> NaiveDateTime.add(20000)
        )

      old_summary = summary_fixture(%{summary_interval: old_range})
      summary_fixture(%{summary_interval: future_range})
      assert Summaries.list_summaries(filters: [before: NaiveDateTime.utc_now()]) == [old_summary]
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
