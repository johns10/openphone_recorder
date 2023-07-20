defmodule Discussit.Events.Openphone.ProjectorTest do
  use Discussit.DataCase
  use Discussit.AudioCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Discussit.Events.Openphone.Projector
  alias Discussit.Calls.Call
  alias Discussit.Statements.Statement
  alias Discussit.OpenphoneFixtures
  alias Discussit.Events
  alias Discussit.PhoneNumbers.PhoneNumber
  alias Discussit.Contacts.Contact

  ExVCR.Config.filter_request_headers("Authorization")

  setup_all do
    HTTPoison.start()
    Application.put_env(:discussit, :http_provider, HTTPoison)
    :ok
  end

  describe "CallRinging" do
    test "gets projected to the database properly" do
      account = Discussit.AccountsFixtures.account_fixture()

      assert {:ok, %Call{}} =
               OpenphoneFixtures.call_ringing()
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end
  end

  describe "MessageReceived" do
    test "projects a received message" do
      account = Discussit.AccountsFixtures.account_fixture()

      use_cassette "vector_create" do
        assert {:ok, %Statement{}} =
                 OpenphoneFixtures.message_received()
                 |> Events.cast_event()
                 |> Projector.apply(account.id)
      end
    end
  end

  describe "MessageDelivered" do
    test "projects a delivered message" do
      account = Discussit.AccountsFixtures.account_fixture()

      assert {:ok, %Statement{}} =
               OpenphoneFixtures.message_delivered()
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end
  end

  describe "CallCompleted" do
    test "gets projected to the database properly" do
      ExVCR.Config.filter_request_headers("Authorization")
      account = Discussit.AccountsFixtures.account_fixture()

      use_cassette("call_completed_projection") do
        assert {:ok, %Call{statements: [statement]}} =
                 OpenphoneFixtures.call_completed()
                 |> Events.cast_event()
                 |> Projector.apply(account.id)

        assert statement.content =~ "Hello, this is Susanna. Hi, Susanna, this is Jen."
      end
    end
  end

  describe "CallRecordingCompleted" do
    test "gets projected to the database properly" do
      ExVCR.Config.filter_request_headers("Authorization")
      account = Discussit.AccountsFixtures.account_fixture()

      use_cassette("call_recording_projection", match_requests_on: [:request_body]) do
        assert {:ok,
                %Call{
                  statements: [
                    %{content: " Thank you."},
                    %{content: ""},
                    %{content: " Hello? Hi, Troy. Uh-huh. Okay, perfect. All right. Thank you."}
                    | _
                  ]
                }} =
                 OpenphoneFixtures.call_recording_completed()
                 |> Events.cast_event()
                 |> Projector.apply(account.id)
      end
    end
  end

  describe "ContactUpdated" do
    test "creates a contact when it doesn't exist" do
      account = Discussit.AccountsFixtures.account_fixture()

      assert {:ok,
              %Contact{
                phone_numbers: [
                  %PhoneNumber{
                    value: %EctoPhoneNumber{e164: 12_566_581_234}
                  }
                ]
              }} =
               OpenphoneFixtures.contact_updated(%{phone_numbers: ["12566581234"]})
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end

    test "adds a phone number to an existing contact" do
      account = Discussit.AccountsFixtures.account_fixture()

      OpenphoneFixtures.contact_updated(%{phone_numbers: ["12566581234"]})
      |> Events.cast_event()
      |> Projector.apply(account.id)

      assert {:ok,
              %Contact{
                phone_numbers: [
                  %PhoneNumber{
                    value: %EctoPhoneNumber{e164: 12_566_581_234}
                  }
                ]
              }} =
               OpenphoneFixtures.contact_updated(%{phone_numbers: ["12566581234"]})
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end
  end
end
