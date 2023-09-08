defmodule Discussit.ConversationsTest do
  alias Discussit.AccountsFixtures
  use Discussit.DataCase

  alias Discussit.Conversations

  describe "conversations" do
    alias Discussit.Conversations.Conversation

    import Discussit.ConversationsFixtures
    import Discussit.ParticipantsFixtures
    import Discussit.PhoneNumbersFixtures
    import Discussit.ContactsFixtures
    import Discussit.ContactPhoneNumbersFixtures
    import Discussit.AccountsFixtures
    import Discussit.StatementsFixtures
    import Discussit.TimestampFixtures

    @invalid_attrs %{}

    test "list_conversations/0 returns all conversations" do
      conversation = conversation_fixture()
      assert Conversations.list_conversations() == [conversation]
    end

    test "ordering by last statement" do
      %{id: con_id} = con = conversation_fixture()
      %{id: con2_id} = con2 = conversation_fixture()
      statement_fixture(%{conversation_id: con.id, occurred_at: thirty_minutes_ago()})
      statement_fixture(%{conversation_id: con.id, occurred_at: ten_minutes_ago()})
      statement_fixture(%{conversation_id: con2.id, occurred_at: thirty_minutes_ago()})
      statement_fixture(%{conversation_id: con2.id, occurred_at: forty_minutes_ago()})

      assert [%{id: ^con_id}, %{id: ^con2_id}] =
               Conversations.list_conversations(order_bys: [last_statement_occurred_at: :desc])

      assert [%{id: ^con2_id}, %{id: ^con_id}] =
               Conversations.list_conversations(order_bys: [last_statement_occurred_at: :asc])
    end

    test "list_conversation_summary works" do
      account = account_fixture()
      con = conversation_fixture(%{account_id: account.id})
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

      [conversation] = Conversations.list_conversation_summary(account.id)

      assert Enum.any?(conversation.participants, &(&1.phone_number.id == pn_id))
      assert Enum.any?(conversation.participants, &(&1.phone_number.id == pn2_id))
    end

    test "list_conversation_summary orders participants with contacts first" do
      account = account_fixture()
      con = conversation_fixture(%{account_id: account.id})
      pn2 = phone_number_fixture()
      pn = phone_number_fixture()
      participant_fixture(%{conversation_id: con.id, phone_number_id: pn.id})
      participant_fixture(%{conversation_id: con.id, phone_number_id: pn2.id})
      c = contact_fixture(%{relationship: :primary})
      contact_phone_number_fixture(%{contact_id: c.id, phone_number_id: pn.id})
      pn_id = pn.id
      pn2_id = pn2.id

      [conversation] = Conversations.list_conversation_summary(account.id)

      assert [%{phone_number: %{id: ^pn2_id}}, %{phone_number: %{id: ^pn_id}}] =
               conversation.participants |> Enum.sort(&(&1.inserted_at > &2.inserted_at))
    end

    test "get_conversation!/1 returns the conversation with given id" do
      conversation = conversation_fixture()
      assert Conversations.get_conversation!(conversation.id) == conversation
    end

    test "upsert_conversation/1 with valid data creates a conversation" do
      valid_attrs = %{
        external_id: "asd08hlaihdoih",
        source: :openphone,
        account_id: AccountsFixtures.account_fixture().id
      }

      old_converation = conversation_fixture(%{external_id: "asd08hlaihdoih", source: :openphone})

      assert {:ok, %Conversation{} = conversation} =
               Conversations.upsert_conversation(valid_attrs)

      assert conversation.external_id == old_converation.external_id
    end

    test "create_conversation/1 with valid data creates a conversation" do
      valid_attrs = %{
        external_id: "asd08hlaihdoih",
        source: :openphone,
        account_id: AccountsFixtures.account_fixture().id
      }

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
