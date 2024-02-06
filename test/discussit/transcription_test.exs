defmodule Discussit.TranscriptionTest do
  use Discussit.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Discussit.MeetingsFixtures
  alias Discussit.Transcription
  alias Discussit.Meetings.Meeting
  import Discussit.UsersFixtures
  import Discussit.AccountsFixtures

  describe "transcription of meetings" do
    test "base case" do
      user = user_fixture()
      account = account_fixture()
      bucket = Application.get_env(:discussit, :bucket)
      key = "test-file.mp3"

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("single_file_upload") do
        "./test/support/fixtures/256_to_623.mp3"
        |> ExAws.S3.Upload.stream_file()
        |> ExAws.S3.upload(bucket, key)
        |> ExAws.request()
      end

      use_cassette("aai_transcription") do
        meeting =
          meeting_fixture(%{files: [%{key: key, bucket: bucket, metadata: %{type: "audio/mp4"}}]})

        use_cassette("256_to_623_retrieve_transcript_call") do
          Transcription.start([meeting.id], %Meeting{},
            user_id: user.id,
            account_id: account.id
          )
        end
      end
    end
  end
end
