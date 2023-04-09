defmodule OpenphoneRecorder.Events.Openphone.ProjectorTest do
  use OpenphoneRecorder.DataCase
  use OpenphoneRecorder.HTTPCase
  use OpenphoneRecorder.AudioCase

  import Mox
  import OpenphoneRecorder.HTTPFixtures

  alias OpenphoneRecorder.Calls.Call
  alias OpenphoneRecorder.Statements.Statement
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
      OpenphoneRecorder.MockHTTP
      |> expect(:get, fn _, _, _ -> {:ok, %{status_code: 200, body: ""}} end)
      |> expect(:post, 2, fn _, {_, [_, _, {:file, string}]}, _, _ ->
        string
        |> String.split("/")
        |> Enum.reverse()
        |> Enum.at(0)
        |> case do
          "2channell.mp3" -> left_openai_speech()
          "2channelr.mp3" -> right_openai_speech()
        end
      end)

      assert {:ok, %Call{statements: [%{content: " Hello."}, %{content: " Goodbye."}]}} =
               OpenphoneFixtures.call_recording_completed()
               |> Events.cast_event()
               |> Projector.apply()
    end

    test "returns errors when speech has invalid attrs" do
      OpenphoneRecorder.MockHTTP
      |> expect(:get, fn _, _, _ -> {:ok, %{status_code: 200, body: ""}} end)
      |> expect(:post, 2, fn _, _, _, _ -> bogus_openai_speech() end)

      assert {:error, %{statements: [_, _]}} =
               OpenphoneFixtures.call_recording_completed()
               |> Events.cast_event()
               |> Projector.apply()
    end
  end

  describe "MessageReceived" do
    test "projects a received message" do
      assert {:ok, %Statement{}} =
               OpenphoneFixtures.message_received()
               |> Events.cast_event()
               |> Projector.apply()
    end
  end

  describe "MessageDelivered" do
    test "projects a delivered message" do
      assert {:ok, %Statement{}} =
               OpenphoneFixtures.message_delivered()
               |> Events.cast_event()
               |> Projector.apply()
    end
  end
end
