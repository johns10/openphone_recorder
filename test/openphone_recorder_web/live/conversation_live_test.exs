defmodule OpenphoneRecorderWeb.ConversationLiveTest do
  use OpenphoneRecorderWeb.ConnCase

  import Phoenix.LiveViewTest
  import OpenphoneRecorder.ConversationsFixtures

  defp create_conversation(_) do
    conversation = conversation_fixture()
    %{conversation: conversation}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_conversation]

    test "lists all conversations", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/conversations")

      assert html =~ "Listing Conversations"
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_conversation]

    test "displays conversation", %{conn: conn, conversation: conversation} do
      {:ok, _show_live, html} = live(conn, ~p"/conversations/#{conversation}")

      assert html =~ "Show Conversation"
    end
  end
end
