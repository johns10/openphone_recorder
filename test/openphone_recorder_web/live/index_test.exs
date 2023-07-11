defmodule OpenphoneRecorderWeb.IndexLive.IndexTest do
  use OpenphoneRecorderWeb.ConnCase

  import Phoenix.LiveViewTest
  import OpenphoneRecorder.ConversationsFixtures
  import OpenphoneRecorder.PhoneNumbersFixtures
  import OpenphoneRecorder.ParticipantsFixtures
  import OpenphoneRecorder.AccountsFixtures
  import OpenphoneRecorder.AccountUsersFixtures

  defp create_conversation(%{account: account}) do
    conversation = conversation_fixture(%{account_id: account.id})
    %{conversation: conversation}
  end

  defp fixture(%{account: account}) do
    conversation = conversation_fixture(%{account_id: account.id})
    phone_number_one = phone_number_fixture()
    phone_number_two = phone_number_fixture()

    participant_one =
      participant_fixture(%{
        conversation_id: conversation.id,
        phone_number_id: phone_number_one.id
      })

    participant_two =
      participant_fixture(%{
        conversation_id: conversation.id,
        phone_number_id: phone_number_two.id
      })

    %{conversation: conversation, phone_number: phone_number_one, participant: participant_one}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :user_setup, :fixture]

    test "lists all conversations", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/home")

      assert html =~ "Listing Conversations"
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

  describe "Authorized Index" do
    setup [:register_and_log_in_user, :user_setup, :permit, :fixture]

    test "account picker renders", %{conn: conn, account: account} do
      {:ok, _index_live, html} = live(conn, ~p"/home")

      assert html =~ account.name
    end
  end

  describe "Unauthorized Show" do
    setup [:register_and_log_in_user, :user_setup, :fixture]

    test "displays conversation", %{conn: conn, conversation: c, phone_number: pn} do
      {:error, {:live_redirect, _}} = live(conn, ~p"/conversations/#{c}")
    end
  end

  describe "Authorized Show" do
    setup [:register_and_log_in_user, :user_setup, :fixture, :permit]

    test "displays conversation", %{conn: conn, conversation: c, phone_number: pn} do
      {:ok, _show_live, html} = live(conn, ~p"/conversations/#{c}")

      assert html =~ to_string(pn.value)
    end
  end
end
