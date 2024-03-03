defmodule Discussit.Events.Openphone.ProjectorTest do
  alias Discussit.Participants
  alias Discussit.PhoneNumbers
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

      assert {:ok, %Call{from_participant_id: from, to_participant_id: to}} =
               OpenphoneFixtures.call_ringing()
               |> Events.cast_event()
               |> Projector.apply(account.id)

      assert not is_nil(from)
      assert not is_nil(to)
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

    test "projects a received message to multiple receivers" do
      account = Discussit.AccountsFixtures.account_fixture()

      event =
        OpenphoneFixtures.message_received(:multiple_recipients)
        |> Events.cast_event()

      expected_phone_numbers = 1 + Enum.count(String.split(event.data.to, ","))

      assert {:ok, %Statement{}} = Projector.apply(event, account.id)

      assert PhoneNumbers.list_phone_numbers() |> Enum.count() == expected_phone_numbers
      assert Participants.list_participants() |> Enum.count() == expected_phone_numbers
    end

    test "resolves a contact" do
      account = Discussit.AccountsFixtures.account_fixture()
      contact = Discussit.ContactsFixtures.contact_fixture()
      phone_number = Discussit.PhoneNumbersFixtures.phone_number_fixture(%{value: "+18005550100"})

      Discussit.ContactPhoneNumbersFixtures.contact_phone_number_fixture(%{
        phone_number_id: phone_number.id,
        contact_id: contact.id
      })

      assert {:ok, statement = %Statement{}} =
               OpenphoneFixtures.message_received()
               |> Events.cast_event()
               |> Projector.apply(account.id)

      assert contact.id ==
               statement
               |> Discussit.Repo.preload([:participant])
               |> Map.get(:participant)
               |> Map.get(:contact_id)
    end

    test "doesn't resolve indeterminate contacts" do
      account = Discussit.AccountsFixtures.account_fixture()
      contact = Discussit.ContactsFixtures.contact_fixture()
      other_contact = Discussit.ContactsFixtures.contact_fixture()
      phone_number = Discussit.PhoneNumbersFixtures.phone_number_fixture(%{value: "+18005550100"})

      Discussit.ContactPhoneNumbersFixtures.contact_phone_number_fixture(%{
        phone_number_id: phone_number.id,
        contact_id: contact.id
      })

      Discussit.ContactPhoneNumbersFixtures.contact_phone_number_fixture(%{
        phone_number_id: phone_number.id,
        contact_id: other_contact.id
      })

      assert {:ok, statement = %Statement{}} =
               OpenphoneFixtures.message_received()
               |> Events.cast_event()
               |> Projector.apply(account.id)

      assert nil ==
               statement
               |> Discussit.Repo.preload([:participant])
               |> Map.get(:participant)
               |> Map.get(:contact_id)
    end

    test "doesn't change the contact" do
      account = Discussit.AccountsFixtures.account_fixture()
      contact = Discussit.ContactsFixtures.contact_fixture()
      other_contact = Discussit.ContactsFixtures.contact_fixture()
      phone_number = Discussit.PhoneNumbersFixtures.phone_number_fixture(%{value: "+18005550100"})

      contact_phone_number =
        Discussit.ContactPhoneNumbersFixtures.contact_phone_number_fixture(%{
          phone_number_id: phone_number.id,
          contact_id: contact.id
        })

      {:ok, statement = %Statement{}} =
        OpenphoneFixtures.message_received()
        |> Events.cast_event()
        |> Projector.apply(account.id)

      statement
      |> Discussit.Repo.preload([:participant])
      |> Map.get(:participant)
      |> Map.get(:contact_id)

      Discussit.ContactPhoneNumbers.delete_contact_phone_number(contact_phone_number)

      Discussit.ContactPhoneNumbersFixtures.contact_phone_number_fixture(%{
        phone_number_id: phone_number.id,
        contact_id: other_contact.id
      })

      {:ok, statement_2 = %Statement{}} =
        OpenphoneFixtures.message_received()
        |> Events.cast_event()
        |> Projector.apply(account.id)

      assert contact.id ==
               statement_2
               |> Discussit.Repo.preload([:participant])
               |> Map.get(:participant)
               |> Map.get(:contact_id)
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

    test "projects events with missing created at" do
      account = Discussit.AccountsFixtures.account_fixture()

      assert {:ok, %Statement{}} =
               """
               {"id": "EV36b7f4cdcbfb42a68ffda55df31a8bee", "data": {"object": {"id": "AC3a9ddb4a29af4452b9ab8de8a63fa9c8", "to": "+19283002716", "body": "Rayna, please invoice 175 on 20230823-46587", "from":"+16232464213", "media": [], "object": "message", "status": "delivered", "userId": "UShk0sCp2n", "createdAt": "2023-09-07T13:18:02.015Z", "createdBy": "UShk0sCp2n", "direction": "outgoing", "phoneNumberId": "PNMUD2Wja7", "conversationId": "CN881a0ac7ead8411d8c8e7691da6b463c"}}, "type": "message.delivered", "object": "event", "apiVersion": "v3"}
               """
               |> Jason.decode!()
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end
  end

  describe "CallCompleted" do
    test "gets projected to the database properly" do
      ExVCR.Config.filter_request_headers("Authorization")
      account = Discussit.AccountsFixtures.account_fixture()

      use_cassette("call_completed_projection") do
        {:ok, %Call{voicemail: file}} =
          OpenphoneFixtures.call_completed()
          |> Events.cast_event()
          |> Projector.apply(account.id)

        assert {:ok, %{status_code: 200}} =
                 ExAws.S3.head_object(file.bucket, file.key) |> ExAws.request()

        assert file.metadata.type == "audio/mpeg"
      end
    end

    test "two voicemails don't get overwritten" do
      ExVCR.Config.filter_request_headers("Authorization")
      account = Discussit.AccountsFixtures.account_fixture()

      use_cassette("2_voicemail_call_completed_projection") do
        {:ok, %Call{voicemail: _file}} =
          OpenphoneFixtures.call_completed()
          |> Events.cast_event()
          |> Projector.apply(account.id)

        {:ok, %Call{voicemail: _file}} =
          OpenphoneFixtures.call_completed()
          |> Events.cast_event()
          |> Projector.apply(account.id)
      end
    end
  end

  describe "CallRecordingCompleted" do
    test "gets projected to the database properly" do
      ExVCR.Config.filter_request_headers("Authorization")
      account = Discussit.AccountsFixtures.account_fixture()

      use_cassette("call_recording_projection") do
        {:ok, %Call{call_recording: file}} =
          OpenphoneFixtures.call_recording_completed()
          |> Events.cast_event()
          |> Projector.apply(account.id)

        assert {:ok, %{status_code: 200}} =
                 ExAws.S3.head_object(file.bucket, file.key) |> ExAws.request()

        assert file.metadata.type == "audio/mpeg"
      end
    end

    test "call recording completed, then call answered doesn't overwrite the file" do
      ExVCR.Config.filter_request_headers("Authorization")
      account = Discussit.AccountsFixtures.account_fixture()
      id = "ACbaee66e137f0467dbed5ad4bc8d60802"

      use_cassette("call_recording_reprojection") do
        {:ok, %Call{call_recording: file}} =
          OpenphoneFixtures.call_recording_completed(%{id: id})
          |> Events.cast_event()
          |> Projector.apply(account.id)

        assert {:ok, %{status_code: 200}} =
                 ExAws.S3.head_object(file.bucket, file.key) |> ExAws.request()

        assert file.metadata.type == "audio/mpeg"

        {:ok, %Call{} = call} =
          OpenphoneFixtures.call_ringing(%{id: id})
          |> Events.cast_event()
          |> Projector.apply(account.id)

        assert not is_nil(call.call_recording)
      end
    end

    test "call recording completed, then call completed without voicemail doesn't overwrite the file" do
      ExVCR.Config.filter_request_headers("Authorization")
      account = Discussit.AccountsFixtures.account_fixture()
      id = "ACbaee66e137f0467dbed5ad4bc8d60802"

      use_cassette("call_recording_reprojection_2") do
        {:ok, %Call{call_recording: file}} =
          OpenphoneFixtures.call_recording_completed(%{id: id})
          |> Events.cast_event()
          |> Projector.apply(account.id)

        assert {:ok, %{status_code: 200}} =
                 ExAws.S3.head_object(file.bucket, file.key) |> ExAws.request()

        assert file.metadata.type == "audio/mpeg"

        {:ok, %Call{} = call} =
          OpenphoneFixtures.call_completed_no_voicemail(%{id: id})
          |> Events.cast_event()
          |> Projector.apply(account.id)

        assert not is_nil(call.call_recording)
      end
    end
  end

  describe "ContactDeleted" do
    test "works" do
      account = Discussit.AccountsFixtures.account_fixture()

      Discussit.ContactsFixtures.contact_fixture(%{
        external_id: "CT643452a4da87a11f79bbc55b",
        source: :openphone
      })

      assert {:ok, %Contact{}} =
               OpenphoneFixtures.contact_deleted(%{external_id: "CT643452a4da87a11f79bbc55b"})
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end

    test "two contacts, same phone number" do
      account = Discussit.AccountsFixtures.account_fixture()

      OpenphoneFixtures.contact_updated(%{
        phone_numbers: ["12566581234"],
        external_id: "CT643452a4da87a11f79bbc55b"
      })
      |> Events.cast_event()
      |> Projector.apply(account.id)

      OpenphoneFixtures.contact_updated(%{
        phone_numbers: ["12566581234"],
        external_id: "CT643452a4da87a11f79bbc55c"
      })
      |> Events.cast_event()
      |> Projector.apply(account.id)

      assert {:ok, %Contact{}} =
               OpenphoneFixtures.contact_deleted(%{external_id: "CT643452a4da87a11f79bbc55b"})
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end
  end

  describe "ContactUpdated" do
    test "Does nothing when the phone number isn't valid" do
      account = Discussit.AccountsFixtures.account_fixture()

      assert {:error, _} =
               OpenphoneFixtures.contact_updated(%{phone_number: "125665812"})
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end

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
                  },
                  %PhoneNumber{
                    value: %EctoPhoneNumber{e164: 12_566_581_235}
                  }
                ]
              }} =
               OpenphoneFixtures.contact_updated(%{phone_number: ["12566581234", "12566581235"]})
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end

    test "handles no phone numbers" do
      account = Discussit.AccountsFixtures.account_fixture()

      assert {:ok, %Contact{phone_numbers: []}} =
               OpenphoneFixtures.contact_updated(%{phone_number: nil})
               |> Events.cast_event()
               |> Projector.apply(account.id)
    end

    test "handles it when another contact gets that phone number" do
      account = Discussit.AccountsFixtures.account_fixture()

      Discussit.ContactsFixtures.contact_fixture(%{
        external_id: "CT643452a4da87a11f79bbc55c",
        source: :openphone
      })

      Discussit.ContactsFixtures.contact_fixture(%{
        external_id: "CT643452a4da87a11f79bbc55b",
        source: :openphone
      })

      OpenphoneFixtures.contact_updated(%{
        phone_numbers: ["12566581234"],
        external_id: "CT643452a4da87a11f79bbc55c"
      })
      |> Events.cast_event()
      |> Projector.apply(account.id)

      OpenphoneFixtures.contact_updated(%{
        phone_numbers: ["12566581235"],
        external_id: "CT643452a4da87a11f79bbc55b"
      })
      |> Events.cast_event()
      |> Projector.apply(account.id)

      OpenphoneFixtures.contact_updated(%{
        phone_numbers: ["12566581234"],
        external_id: "CT643452a4da87a11f79bbc55b"
      })
      |> Events.cast_event()
      |> Projector.apply(account.id)
    end
  end
end
