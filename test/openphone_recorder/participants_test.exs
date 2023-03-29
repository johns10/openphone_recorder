defmodule OpenphoneRecorder.ParticipantsTest do
  use OpenphoneRecorder.DataCase

  alias OpenphoneRecorder.Participants

  describe "participants" do
    alias OpenphoneRecorder.Participants.Participant

    import OpenphoneRecorder.ParticipantsFixtures
    import OpenphoneRecorder.ConversationsFixtures
    import OpenphoneRecorder.PhoneNumbersFixtures

    @invalid_attrs %{conversation_id: Ecto.UUID.generate(), phone_number_id: Ecto.UUID.generate()}

    test "list_participants/0 returns all participants" do
      participant = participant_fixture()
      assert Participants.list_participants() == [participant]
    end

    test "get_participant!/1 returns the participant with given id" do
      participant = participant_fixture()
      assert Participants.get_participant!(participant.id) == participant
    end

    test "create_participant/1 with valid data creates a participant" do
      valid_attrs = %{}

      assert {:ok, %Participant{}} = Participants.create_participant(valid_attrs)
    end

    test "create_participant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Participants.create_participant(@invalid_attrs)
    end

    test "update_participant/2 with valid data updates the participant" do
      participant = participant_fixture()
      update_attrs = %{}

      assert {:ok, %Participant{}} = Participants.update_participant(participant, update_attrs)
    end

    test "update_participant/2 with invalid data returns error changeset" do
      participant = participant_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Participants.update_participant(participant, @invalid_attrs)

      assert participant == Participants.get_participant!(participant.id)
    end

    test "upsert_participant/1 does nothing" do
      phone_number = phone_number_fixture()
      conversation = conversation_fixture()

      attrs = %{
        phone_number_id: phone_number.id,
        conversation_id: conversation.id
      }

      Participants.create_participant(attrs)

      assert {:ok, participant = %Participant{}} = Participants.upsert_participant(attrs)

      assert participant.phone_number_id == phone_number.id
      assert participant.conversation_id == conversation.id
    end

    test "delete_participant/1 deletes the participant" do
      participant = participant_fixture()
      assert {:ok, %Participant{}} = Participants.delete_participant(participant)
      assert_raise Ecto.NoResultsError, fn -> Participants.get_participant!(participant.id) end
    end

    test "change_participant/1 returns a participant changeset" do
      participant = participant_fixture()
      assert %Ecto.Changeset{} = Participants.change_participant(participant)
    end
  end
end
