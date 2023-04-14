defmodule OpenphoneRecorderWeb.IndexLive.IndexTest do
  use OpenphoneRecorderWeb.ConnCase

  import Phoenix.LiveViewTest
  import OpenphoneRecorder.ConversationsFixtures
  import OpenphoneRecorder.PhoneNumbersFixtures
  import OpenphoneRecorder.ParticipantsFixtures

  defp create_conversation(_) do
    conversation = conversation_fixture()
    %{conversation: conversation}
  end

  defp fixture(_) do
    conversation = conversation_fixture()
    phone_number = phone_number_fixture()
    participant = participant_fixture(%{conversation_id: conversation.id})
  end

  describe "Index" do
    setup [:create_conversation]

    test "lists all conversations", %{conn: conn, conversation: conversation} do
      {:ok, _index_live, html} = live(conn, ~p"/conversations")

      assert html =~ "Listing Conversations"
    end
  end

  describe "Show" do
    setup [:create_conversation]

    test "displays conversation", %{conn: conn, conversation: conversation} do
      {:ok, _show_live, html} = live(conn, ~p"/conversations/#{conversation}")

      assert html =~ "Show Conversation"
    end
  end
end
