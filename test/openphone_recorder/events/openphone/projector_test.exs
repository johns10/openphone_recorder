defmodule OpenphoneRecorder.Events.Openphone.ProjectorTest do
  use OpenphoneRecorder.DataCase
  use OpenphoneRecorder.AudioCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias OpenphoneRecorder.Events.Openphone.Projector
  alias OpenphoneRecorder.Calls.Call
  alias OpenphoneRecorder.Statements.Statement
  alias OpenphoneRecorder.OpenphoneFixtures
  alias OpenphoneRecorder.Events
  alias OpenphoneRecorder.PhoneNumbers.PhoneNumber
  alias OpenphoneRecorder.Contacts.Contact

  setup_all do
    HTTPoison.start()
    Application.put_env(:openphone_recorder, :http_provider, HTTPoison)
    ExVCR.Config.filter_request_headers("Authorization")
    :ok
  end

  describe "CallRinging" do
    test "gets projected to the database properly" do
      assert {:ok, %Call{}} =
               OpenphoneFixtures.call_ringing()
               |> Events.cast_event()
               |> Projector.apply()
    end
  end

  describe "MessageReceived" do
    test "projects a received message" do
      use_cassette "vector_create" do
        assert {:ok, %Statement{}} =
                 OpenphoneFixtures.message_received()
                 |> Events.cast_event()
                 |> Projector.apply()
      end
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

  describe "CallCompleted" do
    test "gets projected to the database properly" do
      use_cassette("call_completed_projection") do
        assert {:ok, %Call{statements: [statement]}} =
                 OpenphoneFixtures.call_completed()
                 |> Events.cast_event()
                 |> Projector.apply()

        assert statement.content =~ "Hello, this is Susanna. Hi, Susanna, this is Jen."
      end
    end
  end

  describe "CallRecordingCompleted" do
    test "gets projected to the database properly" do
      use_cassette("call_recording_projection", match_requests_on: [:request_body]) do
        assert {:ok,
                %Call{
                  statements: [
                    %{content: " Hello. Hi, Troy."},
                    %{content: " Hey, Joe."},
                    %{content: " Hey, yeah, I talked to Kayla."} | _
                  ]
                }} =
                 OpenphoneFixtures.call_recording_completed()
                 |> Events.cast_event()
                 |> Projector.apply()
      end
    end
  end

  describe "ContactUpdated" do
    test "creates a contact when it doesn't exist" do
      assert {:ok,
              %Contact{
                phone_numbers: [
                  %PhoneNumber{
                    phone_number: %EctoPhoneNumber{e164: 12_566_581_234}
                  }
                ]
              }} =
               OpenphoneFixtures.contact_updated(%{phone_numbers: ["12566581234"]})
               |> Events.cast_event()
               |> Projector.apply()
    end

    test "adds a phone number to an existing contact" do
      OpenphoneFixtures.contact_updated(%{phone_numbers: ["12566581234"]})
      |> Events.cast_event()
      |> Projector.apply()

      assert {:ok,
              %Contact{
                phone_numbers: [
                  %PhoneNumber{
                    phone_number: %EctoPhoneNumber{e164: 12_566_581_234}
                  }
                ]
              }} =
               OpenphoneFixtures.contact_updated(%{phone_numbers: ["12566581234"]})
               |> Events.cast_event()
               |> Projector.apply()
    end
  end
end
