defmodule DiscussitWeb.MeetingLiveTest do
  use DiscussitWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Phoenix.LiveViewTest
  import Discussit.MeetingsFixtures
  import Discussit.StatementsFixtures
  import Discussit.ParticipantsFixtures

  # @create_attrs %{occurred_at: "2023-08-27T17:35:00.000000", provider: :zoom}
  # @update_attrs %{occurred_at: "2023-08-28T17:35:00.000000", provider: :teams}
  # @invalid_attrs %{occurred_at: nil, provider: nil}

  defp create_meeting(_) do
    meeting = meeting_fixture()
    %{meeting: meeting}
  end

  defp create_participant(_) do
    participant = participant_fixture(%{name: "speaker a", phone_number_id: nil})
    %{participant: participant}
  end

  defp create_statement(%{meeting: %{id: meeting_id}, participant: %{id: participant_id}}) do
    statement = statement_fixture(%{meeting_id: meeting_id, participant_id: participant_id})
    %{statement: statement}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_meeting]

    test "lists all meetings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/meetings")

      assert html =~ "Listing Meetings"
    end

    test "file upload", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      assert index_live
             |> element("#import-zoom-meetings")
             |> render_hook(:"create-meeting", %{
               files: [%{name: "whootie", key: Ecto.UUID.generate()}],
               name: "2022-08-13 12.53.05 John Davenport's Zoom Meeting",
               source: "zoom"
             }) =~ "John Davenport"
    end

    test "deletes meeting in listing", %{conn: conn, meeting: meeting} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      assert index_live |> element("#meetings-#{meeting.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#meetings-#{meeting.id}")
    end

    test "transcription", %{conn: conn, meeting: meeting, user: user} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      DiscussitWeb.Endpoint.subscribe("user_#{user.id}")

      assert index_live
             |> element("#meetings-#{meeting.id} a", "Transcribe")
             |> render_click()

      assert_receive(%{
        event: "meeting_transcription_progress",
        payload: %{projector_status: :in_progress}
      })

      assert_receive(%{
        event: "meeting_transcription_progress",
        payload: %{projector_status: :done}
      })

      assert index_live |> element("#projector-status-#{meeting.id}") |> render() =~
               "hero-check"

      assert index_live |> element("#assignment-status-#{meeting.id}") |> render() =~
               "hero-ellipsis-horizontal"
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_meeting, :create_participant, :create_statement]

    test "displays meeting", %{conn: conn, meeting: meeting, statement: statement} do
      {:ok, _show_live, html} = live(conn, ~p"/meetings/#{meeting}")

      assert html =~ "Show Meeting"
      assert html =~ statement.content
    end

    test "interface for participant assignment", context do
      %{
        conn: conn,
        meeting: meeting,
        statement: statement,
        participant: participant
      } = context

      {:ok, show_live, html} = live(conn, ~p"/meetings/#{meeting}")
      assert html =~ "Show Meeting"
      assert html =~ statement.content
      assert html =~ participant.name
    end
  end
end
