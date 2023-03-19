defmodule OpenphoneRecorder.EventsTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.Events
  alias OpenphoneRecorder.OpenphoneFixtures

  describe "events" do
    alias OpenphoneRecorder.Events.Event

    import OpenphoneRecorder.EventsFixtures

    @invalid_attrs %{payload: nil}

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Events.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Events.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      valid_attrs = %{payload: %{}}

      assert {:ok, %Event{} = event} = Events.create_event(valid_attrs)
      assert event.payload == %{}
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Events.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      update_attrs = %{payload: %{}}

      assert {:ok, %Event{} = event} = Events.update_event(event, update_attrs)
      assert event.payload == %{}
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Events.update_event(event, @invalid_attrs)
      assert event == Events.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Events.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Events.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Events.change_event(event)
    end

    alias OpenphoneRecorder.Events.Openphone

    test "projects call completed" do
      assert %Openphone.CallCompleted{} =
               OpenphoneFixtures.call_completed()
               |> Events.cast_event()
    end

    test "projects call ringing" do
      assert %Openphone.CallRinging{} =
               OpenphoneFixtures.call_ringing()
               |> Events.cast_event()
    end

    test "projects call recording completed" do
      assert %Openphone.CallRecordingCompleted{} =
               OpenphoneFixtures.call_recording_completed()
               |> Events.cast_event()
    end

    test "projects message received" do
      assert %Openphone.MessageReceived{} =
               OpenphoneFixtures.message_received()
               |> Events.cast_event()
    end

    test "projects message delivered" do
      assert %Openphone.MessageDelivered{} =
               OpenphoneFixtures.message_delivered()
               |> Events.cast_event()
    end
  end
end
