defmodule Discussit.LayeredSummarizersTest do
  use Discussit.DataCase

  alias Discussit.LayeredSummarizers

  describe "layered_summarizers" do
    alias Discussit.LayeredSummarizers.LayeredSummarizer

    import Discussit.LayeredSummarizersFixtures

    @invalid_attrs %{name: nil}

    test "list_layered_summarizers/0 returns all layered_summarizers" do
      layered_summarizer = layered_summarizer_fixture()
      assert LayeredSummarizers.list_layered_summarizers() == [layered_summarizer]
    end

    test "get_layered_summarizer!/1 returns the layered_summarizer with given id" do
      layered_summarizer = layered_summarizer_fixture()
      assert LayeredSummarizers.get_layered_summarizer!(layered_summarizer.id) == layered_summarizer
    end

    test "create_layered_summarizer/1 with valid data creates a layered_summarizer" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %LayeredSummarizer{} = layered_summarizer} = LayeredSummarizers.create_layered_summarizer(valid_attrs)
      assert layered_summarizer.name == "some name"
    end

    test "create_layered_summarizer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LayeredSummarizers.create_layered_summarizer(@invalid_attrs)
    end

    test "update_layered_summarizer/2 with valid data updates the layered_summarizer" do
      layered_summarizer = layered_summarizer_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %LayeredSummarizer{} = layered_summarizer} = LayeredSummarizers.update_layered_summarizer(layered_summarizer, update_attrs)
      assert layered_summarizer.name == "some updated name"
    end

    test "update_layered_summarizer/2 with invalid data returns error changeset" do
      layered_summarizer = layered_summarizer_fixture()
      assert {:error, %Ecto.Changeset{}} = LayeredSummarizers.update_layered_summarizer(layered_summarizer, @invalid_attrs)
      assert layered_summarizer == LayeredSummarizers.get_layered_summarizer!(layered_summarizer.id)
    end

    test "delete_layered_summarizer/1 deletes the layered_summarizer" do
      layered_summarizer = layered_summarizer_fixture()
      assert {:ok, %LayeredSummarizer{}} = LayeredSummarizers.delete_layered_summarizer(layered_summarizer)
      assert_raise Ecto.NoResultsError, fn -> LayeredSummarizers.get_layered_summarizer!(layered_summarizer.id) end
    end

    test "change_layered_summarizer/1 returns a layered_summarizer changeset" do
      layered_summarizer = layered_summarizer_fixture()
      assert %Ecto.Changeset{} = LayeredSummarizers.change_layered_summarizer(layered_summarizer)
    end
  end
end
