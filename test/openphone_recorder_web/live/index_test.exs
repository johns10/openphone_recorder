defmodule OpenphoneRecorderWeb.IndexLive.IndexTest do
  use OpenphoneRecorderWeb.ConnCase

  import Phoenix.LiveViewTest
  import OpenphoneRecorder.ConversationsFixtures
  import OpenphoneRecorder.PhoneNumbersFixtures
  import OpenphoneRecorder.ParticipantsFixtures
  import OpenphoneRecorder.AccountsFixtures
  import OpenphoneRecorder.AccountUsersFixtures

  defp create_conversation(_) do
    conversation = conversation_fixture()
    %{conversation: conversation}
  end

  defp fixture(_) do
    conversation = conversation_fixture()
    phone_number = phone_number_fixture()

    participant =
      participant_fixture(%{conversation_id: conversation.id, phone_number_id: phone_number.id})

    %{conversation: conversation, phone_number: phone_number, participant: participant}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :user_setup, :fixture]

    test "lists all conversations", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/conversations")

      assert html =~ "Listing Conversations"
    end

    test "account picker renders", %{conn: conn, account: account} do
      {:ok, _index_live, html} = live(conn, ~p"/home")

      assert html =~ account.name
    end

    test "account picker works", %{conn: conn, user: user} do
      other_account = account_fixture()
      account_user_fixture(%{user_id: user.id, account_id: other_account.id})

      {:ok, index_live, _html} = live(conn, ~p"/home")

      assert index_live
             |> form("#account_picker-form",
               user_setting: %{selected_account_id: other_account.id}
             )
             |> render_change() =~ other_account.name
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
