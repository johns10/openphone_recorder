defmodule DiscussitWeb.IndexLive.IndexTest do
  alias PgRanges.TsRange
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.ConversationsFixtures
  import Discussit.PhoneNumbersFixtures
  import Discussit.ParticipantsFixtures
  import Discussit.AccountsFixtures
  import Discussit.AccountUsersFixtures
  import Discussit.SummarizersFixtures

  defp fixture(%{account: account}) do
    conversation = conversation_fixture(%{account_id: account.id})
    daily_summarizer_fixture()
    weekly_summarizer_fixture()
    monthly_summarizer_fixture()
    yearly_summarizer_fixture()
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

      {:ok, _index_live, _html} = live(conn, ~p"/conversations/#{conversation}")

      # assert index_live
      #        |> element("a#participant-dropdown-toggle-#{participant.id}")
      #        |> render_click() =~ contact_1.first_name

      # assert index_live
      #        |> element("a#participant-contact-option-#{contact_2.id}")
      #        |> render_click() =~ contact_2.first_name
    end

    test "adds a summary", %{conn: conn, conversation: conversation} do
      {:ok, index_live, _html} = live(conn, ~p"/conversations/#{conversation}")

      summarizer = Discussit.SummarizersFixtures.daily_summarizer_fixture()

      cs =
        Discussit.ConversationSummarizersFixtures.conversation_summarizer_fixture(%{
          conversation_id: conversation.id,
          summarizer_id: summarizer.id
        })

      summary =
        Discussit.SummariesFixtures.summary_fixture(%{
          content: "First Summary",
          conversation_id: conversation.id,
          conversation_summarizer_id: cs.id,
          summary_interval: TsRange.new(~N[2018-01-01 00:00:00], ~N[2018-01-01 23:59:59]),
          level: 1
        })

      assert index_live |> element("#zoom-form") |> render_change(%{zoom: 1}) =~
               "First Summary"

      index_live |> render()

      second_summary =
        Discussit.SummariesFixtures.summary_fixture(%{
          content: "Second Summary",
          conversation_id: conversation.id,
          conversation_summarizer_id: cs.id,
          summary_interval: TsRange.new(~N[2018-01-02 00:00:00], ~N[2018-01-02 23:59:59]),
          level: 1
        })

      Process.send(index_live.pid, %{event: "summary_created", payload: second_summary}, [])

      assert render(index_live) =~ "First Summary"
      assert render(index_live) =~ "Second Summary"
    end
  end
end
