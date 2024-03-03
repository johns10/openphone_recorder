defmodule DiscussitWeb.MeetingLiveTest do
  alias Discussit.Conversations
  alias Discussit.Statements
  alias Discussit.Meetings
  alias Discussit.Participants
  alias Discussit.Files.File
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.MeetingsFixtures
  import Discussit.StatementsFixtures
  import Discussit.ParticipantsFixtures
  import Discussit.AccountsFixtures
  import Discussit.AccountUsersFixtures
  import Discussit.ContactsFixtures
  import Discussit.ConversationsFixtures

  # @create_attrs %{occurred_at: "2023-08-27T17:35:00.000000", provider: :zoom}
  # @update_attrs %{occurred_at: "2023-08-28T17:35:00.000000", provider: :teams}
  # @invalid_attrs %{occurred_at: nil, provider: nil}

  defp account_setup(%{user: user}) do
    account = account_fixture()
    account_user_fixture(%{account_id: account.id, user_id: user.id})

    {:ok, user} =
      Discussit.Users.update_selected_account(user, %{selected_account_id: account.id})

    %{account: account, user: user}
  end

  defp create_meeting(%{user: user}) do
    meeting =
      meeting_fixture(%{user_id: user.id, projector_status: :not_started})
      |> Map.put(:files, [
        %File{bucket: "test", key: "test", metadata: %{"type" => "audio/mp4"}}
      ])

    %{meeting: meeting}
  end

  defp create_participant(%{meeting: %{id: meeting_id}}) do
    participant =
      participant_fixture(%{name: "speaker a", phone_number_id: nil, meeting_id: meeting_id})

    %{participant: participant}
  end

  defp create_statement(%{meeting: %{id: meeting_id}, participant: %{id: participant_id}}) do
    statement = statement_fixture(%{meeting_id: meeting_id, participant_id: participant_id})
    %{statement: statement}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :user_setup, :create_meeting]

    test "lists all meetings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/meetings")

      assert html =~ "Listing Meetings"
    end

    test "file upload", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")
      render_hook(index_live, :"upload-started", %{directories: 1})

      assert index_live
             |> element("#import-zoom-meetings")
             |> render_hook(:"create-meeting", %{
               files: [%{name: "whootie", key: Ecto.UUID.generate()}],
               name: "2022-08-13 12.53.05 John Davenport's Zoom Meeting",
               source: "zoom"
             }) =~ "John Davenport"
    end

    test "transcription progress", %{conn: conn, user: user, meeting: meeting} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      refute index_live |> element("#projector-status-#{meeting.id}") |> render() =~ "arrow-path"

      DiscussitWeb.Endpoint.broadcast(
        "user_#{user.id}",
        "meeting_updated",
        meeting |> Map.put(:projector_status, :in_progress)
      )

      assert index_live |> element("#projector-status-#{meeting.id}") |> render() =~ "arrow-path"
    end

    test "deletes meeting in listing", %{conn: conn, meeting: meeting} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      assert index_live |> element("#delete-meetings-#{meeting.id}") |> render_click()
      refute has_element?(index_live, "#meetings-#{meeting.id}")
    end

    test "transcription", %{conn: conn, meeting: meeting} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      use_cassette("256_to_623_aai_call") do
        assert index_live
               |> element("#transcribe-meetings-#{meeting.id}")
               |> render_click()
      end

      {:ok, meeting} = Meetings.update_meeting(meeting, %{projector_status: :done})

      send(index_live.pid, %{event: "meeting_updated", payload: meeting})

      assert index_live |> element("#projector-status-#{meeting.id}") |> render() =~
               "hero-check"

      assert index_live |> element("#assignment-status-#{meeting.id}") |> render() =~
               "hero-ellipsis-horizontal"
    end
  end

  describe "Show" do
    setup [
      :register_and_log_in_user,
      :account_setup,
      :create_meeting,
      :create_participant,
      :create_statement
    ]

    test "displays meeting", %{conn: conn, meeting: meeting, statement: statement} do
      {:ok, _show_live, html} = live(conn, ~p"/meetings/#{meeting}")

      assert html =~ "Show Meeting"
      assert html =~ statement.content
    end
  end

  describe "Show: participant assignment interface" do
    setup [
      :register_and_log_in_user,
      :account_setup,
      :create_meeting,
      :create_participant,
      :create_statement
    ]

    test "base case", context do
      %{
        conn: conn,
        meeting: meeting,
        statement: statement,
        participant: participant,
        account: account
      } = context

      other_account = account_fixture()
      other_contact = contact_fixture(%{account_id: other_account.id})

      contact = contact_fixture(%{account_id: account.id})
      contact_2 = contact_fixture(%{account_id: account.id})

      {:ok, show_live, html} = live(conn, ~p"/meetings/#{meeting}")
      assert html =~ "Show Meeting"
      assert html =~ statement.content
      assert html =~ participant.name

      html = show_live |> element("#find-participant-#{participant.id}") |> render_click()
      assert html =~ contact.first_name
      refute html =~ other_contact.first_name

      refute show_live
             |> element("#contact-search-#{participant.id}")
             |> render_change(%{search: contact.first_name}) =~ contact_2.first_name

      assert show_live
             |> element("#participant-#{participant.id}-contact-#{contact.id}")
             |> render_click() =~
               contact.first_name
    end

    test "assigns meeting to existing conversation", context do
      %{
        conn: conn,
        meeting: meeting,
        participant: participant,
        account: account,
        statement: statement
      } = context

      conversation = %{id: conversation_id} = conversation_fixture()
      contact = contact_fixture(%{account_id: account.id})

      Participants.update_participant(participant, %{conversation_id: conversation.id})
      {:ok, show_live, html} = live(conn, ~p"/meetings/#{meeting}")
      refute html =~ "Assign"
      show_live |> element("#find-participant-#{participant.id}") |> render_click()

      assert show_live
             |> element("#participant-#{participant.id}-contact-#{contact.id}")
             |> render_click()

      assert render(show_live) =~ "Assign"
      assert show_live |> element("#assign-conversation") |> render() =~ contact.first_name

      assert show_live |> element("#assign-conversation-#{conversation.id}") |> render_click() =~
               "assigned"

      assert %{conversation_id: ^conversation_id} = Statements.get_statement!(statement.id)
    end

    test "creates conversation", context do
      %{
        conn: conn,
        meeting: meeting,
        participant: participant,
        account: account
      } = context

      contact = contact_fixture(%{account_id: account.id})
      {:ok, show_live, html} = live(conn, ~p"/meetings/#{meeting}")
      refute html =~ "Create Conversation"
      {:ok, participant} = Participants.update_participant(participant, %{contact_id: contact.id})

      statement =
        statement_fixture(%{
          meeting_id: meeting.id,
          participant_id: participant.id
        })

      Process.send(
        show_live.pid,
        {"", {:participant_contact_set, %{participant | contact: contact}}},
        []
      )

      show_live |> element("#participant-#{participant.id}-contact-#{contact.id}") |> render_click

      :timer.sleep(1000)

      refute show_live |> element("#create-conversation") |> render_click =~ "unassigned"
      [%{id: conversation_id}] = Conversations.list_conversations()
      assert %{conversation_id: ^conversation_id} = Statements.get_statement!(statement.id)
      assert %{conversation_id: ^conversation_id} = Meetings.get_meeting!(meeting.id)
    end

    test "removes from conversation", context do
      %{
        conn: conn,
        meeting: meeting,
        participant: participant,
        account: account
      } = context

      contact = contact_fixture(%{account_id: account.id})
      Participants.update_participant(participant, %{contact_id: contact.id})

      conversation = conversation_fixture()
      {:ok, meeting} = Meetings.update_meeting(meeting, %{conversation_id: conversation.id})

      statement =
        statement_fixture(%{
          meeting_id: meeting.id,
          participant_id: participant.id,
          conversation_id: conversation.id
        })

      {:ok, show_live, _html} = live(conn, ~p"/meetings/#{meeting}")
      assert show_live |> element("#remove-from-conversation") |> render_click =~ "unassigned"
      assert %{conversation_id: nil} = Statements.get_statement!(statement.id)
    end
  end
end
