defmodule OpenphoneRecorder.ConversationsTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.Conversations

  describe "conversations" do
    alias OpenphoneRecorder.Conversations.Conversation

    import OpenphoneRecorder.ConversationsFixtures

    @invalid_attrs %{}

    test "list_conversations/0 returns all conversations" do
      conversation = conversation_fixture()
      assert Conversations.list_conversations() == [conversation]
    end

    test "get_conversation!/1 returns the conversation with given id" do
      conversation = conversation_fixture()
      assert Conversations.get_conversation!(conversation.id) == conversation
    end

    test "upsert_conversation/1 with valid data creates a conversation" do
      valid_attrs = %{external_id: "asd08hlaihdoih", source: :openphone}
      old_converation = conversation_fixture(%{external_id: "asd08hlaihdoih", source: :openphone})

      assert {:ok, %Conversation{} = conversation} =
               Conversations.upsert_conversation(valid_attrs)

      assert conversation.external_id == old_converation.external_id
    end

    test "create_conversation/1 with valid data creates a conversation" do
      valid_attrs = %{external_id: "asd08hlaihdoih", source: :openphone}

      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(valid_attrs)
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(@invalid_attrs)
    end

    test "delete_conversation/1 deletes the conversation" do
      conversation = conversation_fixture()
      assert {:ok, %Conversation{}} = Conversations.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Conversations.get_conversation!(conversation.id) end
    end

    test "change_conversation/1 returns a conversation changeset" do
      conversation = conversation_fixture()
      assert %Ecto.Changeset{} = Conversations.change_conversation(conversation)
    end
  end
end
