defmodule DiscussitWeb.MeetingLiveTest do
  use DiscussitWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Phoenix.LiveViewTest
  import Discussit.MeetingsFixtures

  @create_attrs %{occurred_at: "2023-08-27T17:35:00.000000", provider: :zoom}
  @update_attrs %{occurred_at: "2023-08-28T17:35:00.000000", provider: :teams}
  @invalid_attrs %{occurred_at: nil, provider: nil}

  defp create_meeting(_) do
    meeting = meeting_fixture()
    %{meeting: meeting}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_meeting]

    test "lists all meetings", %{conn: conn} do
      {:ok, index_live, html} = live(conn, ~p"/meetings")

      assert html =~ "Listing Meetings"
    end

    test "file upload", %{conn: conn} do
      {:ok, index_live, html} = live(conn, ~p"/meetings")

      assert index_live
             |> element("#import-zoom-meetings")
             |> render_hook(:"create-meeting", %{
               files: [%{name: "whootie", key: Ecto.UUID.generate()}],
               name: "2022-08-13 12.53.05 John Davenport's Zoom Meeting",
               provider: "zoom"
             }) =~ "John Davenport"
    end

    test "deletes meeting in listing", %{conn: conn, meeting: meeting} do
      {:ok, index_live, _html} = live(conn, ~p"/meetings")

      assert index_live |> element("#meetings-#{meeting.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#meetings-#{meeting.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_meeting]

    test "displays meeting", %{conn: conn, meeting: meeting} do
      {:ok, _show_live, html} = live(conn, ~p"/meetings/#{meeting}")

      assert html =~ "Show Meeting"
    end
  end
end
