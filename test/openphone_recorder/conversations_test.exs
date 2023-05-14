defmodule OpenphoneRecorder.ConversationsTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.Conversations

  describe "conversations" do
    alias OpenphoneRecorder.Conversations.Conversation

    import OpenphoneRecorder.ConversationsFixtures
    import OpenphoneRecorder.ParticipantsFixtures
    import OpenphoneRecorder.PhoneNumbersFixtures
    import OpenphoneRecorder.ContactsFixtures
    import OpenphoneRecorder.ContactPhoneNumbersFixtures

    @invalid_attrs %{}

    test "list_conversations/0 returns all conversations" do
      conversation = conversation_fixture()
      assert Conversations.list_conversations() == [conversation]
    end

    test "list_conversation_summary works" do
      con = conversation_fixture()
      pn = phone_number_fixture()
      pn2 = phone_number_fixture()
      participant_fixture(%{conversation_id: con.id, phone_number_id: pn.id})
      participant_fixture(%{conversation_id: con.id, phone_number_id: pn2.id})
      c2 = contact_fixture(%{relationship: :external})
      c = contact_fixture(%{relationship: :primary})
      contact_phone_number_fixture(%{contact_id: c.id, phone_number_id: pn.id})
      contact_phone_number_fixture(%{contact_id: c2.id, phone_number_id: pn2.id})
      pn_id = pn.id
      pn2_id = pn2.id

      [conversation] = Conversations.list_conversation_summary()
      assert [%{phone_number: %{id: ^pn_id}}, %{phone_number: %{id: ^pn2_id}}] = conversation.participants
    end

    test "list_conversation_summary orders participants with contacts first" do
      con = conversation_fixture()
      pn = phone_number_fixture()
      pn2 = phone_number_fixture()
      participant_fixture(%{conversation_id: con.id, phone_number_id: pn.id})
      participant_fixture(%{conversation_id: con.id, phone_number_id: pn2.id})
      c = contact_fixture(%{relationship: :primary})
      contact_phone_number_fixture(%{contact_id: c.id, phone_number_id: pn.id})
      pn_id = pn.id
      pn2_id = pn2.id

      [conversation] = Conversations.list_conversation_summary()
      assert [%{phone_number: %{id: ^pn_id}}, %{phone_number: %{id: ^pn2_id}}] = conversation.participants
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

      assert {:ok, %Conversation{}} = Conversations.create_conversation(valid_attrs)
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
