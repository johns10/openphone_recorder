defmodule Discussit.MeetingsTest do
  use Discussit.DataCase

  alias Discussit.Meetings

  describe "meetings" do
    alias Discussit.Meetings.Meeting

    import Discussit.MeetingsFixtures

    @invalid_attrs %{occurred_at: nil, source: nil}

    test "list_meetings/0 returns all meetings" do
      meeting = meeting_fixture()
      assert Meetings.list_meetings() == [meeting]
    end

    test "list_meetings/0 doesn't return segments" do
      meeting_fixture(%{segments: [%{"stuff" => "things"}]})
      [meeting] = Meetings.list_meetings()
    end

    test "get_meeting!/1 returns the meeting with given id" do
      meeting = meeting_fixture()
      assert Meetings.get_meeting!(meeting.id) == meeting
    end

    test "create_meeting/1 with valid data creates a meeting" do
      valid_attrs = %{occurred_at: ~N[2023-08-27 17:35:00.000000], source: :zoom}

      assert {:ok, %Meeting{} = meeting} = Meetings.create_meeting(valid_attrs)
      assert meeting.occurred_at == ~N[2023-08-27 17:35:00.000000]
      assert meeting.source == :zoom
    end

    test "create_meeting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Meetings.create_meeting(@invalid_attrs)
    end

    test "update_meeting/2 with valid data updates the meeting" do
      meeting = meeting_fixture()
      update_attrs = %{occurred_at: ~N[2023-08-28 17:35:00.000000], source: :teams}

      assert {:ok, %Meeting{} = meeting} = Meetings.update_meeting(meeting, update_attrs)
      assert meeting.occurred_at == ~N[2023-08-28 17:35:00.000000]
      assert meeting.source == :teams
    end

    test "update_meeting/2 with invalid data returns error changeset" do
      meeting = meeting_fixture()
      assert {:error, %Ecto.Changeset{}} = Meetings.update_meeting(meeting, @invalid_attrs)
      assert meeting == Meetings.get_meeting!(meeting.id)
    end

    test "delete_meeting/1 deletes the meeting" do
      meeting = meeting_fixture()
      assert {:ok, %Meeting{}} = Meetings.delete_meeting(meeting)
      assert_raise Ecto.NoResultsError, fn -> Meetings.get_meeting!(meeting.id) end
    end

    test "change_meeting/1 returns a meeting changeset" do
      meeting = meeting_fixture()
      assert %Ecto.Changeset{} = Meetings.change_meeting(meeting)
    end
  end
end
