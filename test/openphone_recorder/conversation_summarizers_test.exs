defmodule OpenphoneRecorder.ConversationSummarizersTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.ConversationSummarizers
  import OpenphoneRecorder.ConversationsFixtures
  import OpenphoneRecorder.SummarizersFixtures

  defp valid_attrs() do
    %{
      conversation_id: conversation_fixture().id,
      summarizer_id: summarizer_fixture().id
    }
  end

  describe "conversation_summaries" do
    alias OpenphoneRecorder.ConversationSummarizers.ConversationSummarizer

    import OpenphoneRecorder.ConversationSummarizersFixtures

    @invalid_attrs %{conversation_id: nil, summarizer_id: nil}

    test "list_conversation_summaries/0 returns all conversation_summaries" do
      conversation_summarizer = conversation_summarizer_fixture()
      assert ConversationSummarizers.list_conversation_summaries() == [conversation_summarizer]
    end

    test "get_conversation_summarizer!/1 returns the conversation_summarizer with given id" do
      conversation_summarizer = conversation_summarizer_fixture()

      assert ConversationSummarizers.get_conversation_summarizer!(conversation_summarizer.id) ==
               conversation_summarizer
    end

    test "create_conversation_summarizer/1 with valid data creates a conversation_summarizer" do
      assert {:ok, %ConversationSummarizer{} = conversation_summarizer} =
               ConversationSummarizers.create_conversation_summarizer(valid_attrs())
    end

    test "create_conversation_summarizer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               ConversationSummarizers.create_conversation_summarizer(@invalid_attrs)
    end

    test "update_conversation_summarizer/2 with valid data updates the conversation_summarizer" do
      conversation_summarizer = conversation_summarizer_fixture()
      update_attrs = valid_attrs()

      assert {:ok, %ConversationSummarizer{} = conversation_summarizer} =
               ConversationSummarizers.update_conversation_summarizer(
                 conversation_summarizer,
                 update_attrs
               )
    end

    test "update_conversation_summarizer/2 with invalid data returns error changeset" do
      conversation_summarizer = valid_attrs() |> conversation_summarizer_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ConversationSummarizers.update_conversation_summarizer(
                 conversation_summarizer,
                 @invalid_attrs
               )

      assert conversation_summarizer ==
               ConversationSummarizers.get_conversation_summarizer!(conversation_summarizer.id)
    end

    test "delete_conversation_summarizer/1 deletes the conversation_summarizer" do
      conversation_summarizer = conversation_summarizer_fixture()

      assert {:ok, %ConversationSummarizer{}} =
               ConversationSummarizers.delete_conversation_summarizer(conversation_summarizer)

      assert_raise Ecto.NoResultsError, fn ->
        ConversationSummarizers.get_conversation_summarizer!(conversation_summarizer.id)
      end
    end

    test "change_conversation_summarizer/1 returns a conversation_summarizer changeset" do
      conversation_summarizer = conversation_summarizer_fixture()

      assert %Ecto.Changeset{} =
               ConversationSummarizers.change_conversation_summarizer(conversation_summarizer)
    end
  end
end
