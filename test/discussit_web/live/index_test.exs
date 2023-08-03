defmodule DiscussitWeb.IndexLive.IndexTest do
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.ConversationsFixtures
  import Discussit.PhoneNumbersFixtures
  import Discussit.ParticipantsFixtures
  import Discussit.AccountsFixtures
  import Discussit.AccountUsersFixtures

  defp fixture(%{account: account}) do
    conversation = conversation_fixture(%{account_id: account.id})
    phone_number_one = phone_number_fixture()
    phone_number_two = phone_number_fixture()

    participant_one =
      participant_fixture(%{
        conversation_id: conversation.id,
        phone_number_id: phone_number_one.id
      })

    _participant_two =
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

      index_live
      |> form("#account_picker-form",
        user_setting: %{selected_account_id: other_account.id}
      )

      # TODO: Figure out assert |> render_change() =~ other_account.name
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

    test "displays conversation", %{conn: conn, conversation: c} do
      {:error, {:live_redirect, _}} = live(conn, ~p"/conversations/#{c}")
    end
  end

  describe "Authorized Show" do
    setup [:register_and_log_in_user, :user_setup, :fixture, :permit]

    test "displays conversation", %{conn: conn, conversation: c, phone_number: pn} do
      {:ok, _show_live, html} = live(conn, ~p"/conversations/#{c}")

      assert html =~ to_string(pn.value)
    end

    test "updates a contact when participant contact picked", %{
      conn: conn,
      phone_number: phone_number,
      participant: participant,
      conversation: conversation
    } do
      contact_1 = Discussit.ContactsFixtures.contact_fixture()
      contact_2 = Discussit.ContactsFixtures.contact_fixture()

      Discussit.ContactPhoneNumbersFixtures.contact_phone_number_fixture(%{
        phone_number_id: phone_number.id,
        contact_id: contact_1.id
      })

      Discussit.ContactPhoneNumbersFixtures.contact_phone_number_fixture(%{
        phone_number_id: phone_number.id,
        contact_id: contact_2.id
      })

      {:ok, index_live, _html} = live(conn, ~p"/conversations/#{conversation}")

      assert index_live
             |> element("span#participant-dropdown-toggle-#{participant.id}")
             |> render_click() =~ contact_1.first_name

      assert index_live
             |> element("a#participant-contact-option-#{contact_2.id}")
             |> render_click() =~ contact_2.first_name

      # TODO: Validate on actual conversation in sidebar
    end
  end
end
