defmodule DiscussitWeb.TranscriptionControllerTest do
  use DiscussitWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Discussit.UsersFixtures
  import Discussit.MeetingsFixtures
  import Discussit.AccountsFixtures
  import Discussit.AccountUsersFixtures
  import Discussit.CallsFixtures
  import Discussit.ConversationsFixtures
  import Discussit.ParticipantsFixtures

  describe "meeting case" do
    test "works, and message", %{conn: conn} do
      account = account_fixture()
      user = user_fixture()
      account_user_fixture(%{user_id: user.id, account_id: account.id})
      topic = "user_#{user.id}"
      DiscussitWeb.Endpoint.subscribe(topic)

      meeting =
        meeting_fixture(%{
          user_id: user.id,
          transcript_ids: ["b3e6e793-2c07-407a-b9a7-bfab893d2973"]
        })

      payload = %{"status" => "completed"}
      ep = ~p"/api/transcription/complete?account_id=#{account.id}&meeting_id=#{meeting.id}"

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("256_to_623_retrieve_transcript_call") do
        post(conn, ep, payload)
      end

      assert_receive(%{topic: ^topic, event: "meeting_updated", payload: meeting})

      assert meeting.projector_status == :done
    end
  end

  describe "call case" do
    test "works, and message", %{conn: conn} do
      account = account_fixture()
      topic = "account_#{account.id}"
      DiscussitWeb.Endpoint.subscribe(topic)
      conversation = conversation_fixture(%{account_id: account.id})
      participant = participant_fixture()
      participant_two = participant_fixture()

      call =
        call_fixture(%{
          from_participant_id: participant.id,
          to_participant_id: participant_two.id,
          answered_at: NaiveDateTime.utc_now(),
          conversation_id: conversation.id,
          transcript_ids: ["b3e6e793-2c07-407a-b9a7-bfab893d2973"]
        })

      payload = %{"status" => "completed"}
      ep = ~p"/api/transcription/complete?call_id=#{call.id}"

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("256_to_623_retrieve_transcript_call") do
        post(conn, ep, payload)
      end

      assert_receive(%{topic: ^topic, event: "call_updated", payload: call})

      assert call.status == :transcribed
    end
  end
end
