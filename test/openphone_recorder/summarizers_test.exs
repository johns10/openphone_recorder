defmodule Discussit.SummarizersTest do
  use Discussit.DataCase

  alias Discussit.Summarizers

  describe "summarizers" do
    alias Discussit.Summarizers.Summarizer

    import Discussit.SummarizersFixtures

    @invalid_attrs %{prompt: nil}

    test "list_summarizers/0 returns all summarizers" do
      summarizer = summarizer_fixture()
      assert Summarizers.list_summarizers() == [summarizer]
    end

    test "get_summarizer!/1 returns the summarizer with given id" do
      summarizer = summarizer_fixture()
      assert Summarizers.get_summarizer!(summarizer.id) == summarizer
    end

    test "create_summarizer/1 with valid data creates a summarizer" do
      valid_attrs = %{prompt: "some prompt"}

      assert {:ok, %Summarizer{} = summarizer} = Summarizers.create_summarizer(valid_attrs)
      assert summarizer.prompt == "some prompt"
    end

    test "create_summarizer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Summarizers.create_summarizer(@invalid_attrs)
    end

    test "update_summarizer/2 with valid data updates the summarizer" do
      summarizer = summarizer_fixture()
      update_attrs = %{prompt: "some updated prompt"}

      assert {:ok, %Summarizer{} = summarizer} = Summarizers.update_summarizer(summarizer, update_attrs)
      assert summarizer.prompt == "some updated prompt"
    end

    test "update_summarizer/2 with invalid data returns error changeset" do
      summarizer = summarizer_fixture()
      assert {:error, %Ecto.Changeset{}} = Summarizers.update_summarizer(summarizer, @invalid_attrs)
      assert summarizer == Summarizers.get_summarizer!(summarizer.id)
    end

    test "delete_summarizer/1 deletes the summarizer" do
      summarizer = summarizer_fixture()
      assert {:ok, %Summarizer{}} = Summarizers.delete_summarizer(summarizer)
      assert_raise Ecto.NoResultsError, fn -> Summarizers.get_summarizer!(summarizer.id) end
    end

    test "change_summarizer/1 returns a summarizer changeset" do
      summarizer = summarizer_fixture()
      assert %Ecto.Changeset{} = Summarizers.change_summarizer(summarizer)
    end
  end
end
