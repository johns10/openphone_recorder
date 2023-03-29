defmodule OpenphoneRecorder.Events.Openphone.ProjectorTest do
  use OpenphoneRecorder.DataCase
  use OpenphoneRecorder.HTTPCase

  import Mox
  import OpenphoneRecorder.HTTPFixtures

  alias OpenphoneRecorder.Calls.Call
  alias OpenphoneRecorder.OpenphoneFixtures
  alias OpenphoneRecorder.Events
  alias OpenphoneRecorder.Events.Openphone.Projector

  describe "CallRinging" do
    test "gets projected to the database properly" do
      assert {:ok, %Call{}} =
               OpenphoneFixtures.call_ringing()
               |> Events.cast_event()
               |> Projector.apply()
    end
  end

  describe "CallCompleted" do
    setup :verify_on_exit!

    test "gets projected to the database properly" do
      OpenphoneRecorder.MockHTTP
      |> expect(:get, fn _, _, _ -> {:ok, %{status_code: 200, body: ""}} end)
      |> expect(:post, fn _, _, _, _ -> openai_speech() end)

      assert {:ok, %Call{statements: [statement]}} =
               OpenphoneFixtures.call_completed()
               |> Events.cast_event()
               |> Projector.apply()

      assert statement.content == "Hello. Goodbye."
    end
  end

  describe "CallRecordingCompleted" do
    test "gets projected to the database properly" do
      Application.put_env(:openphone_recorder, :http_provider, HTTPoison)

      OpenphoneFixtures.call_recording_completed()
      |> Events.cast_event()
      |> Projector.apply()
    end
  end
end
