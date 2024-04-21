defmodule Discussit.TranscriptionTest do
  use Discussit.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Discussit.MeetingsFixtures
  alias Discussit.Transcription

  describe "transcription of meetings" do
    test "base case" do
      bucket = Application.get_env(:discussit, :bucket)
      key = "test-file.mp3"

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("single_file_upload") do
        path = "./test/support/fixtures/256_to_623.mp3"
        file = File.read!(path)

        ExAws.S3.put_object(bucket, key, file)
        |> ExAws.request!()
      end

      %{id: id} =
        meeting =
        meeting_fixture(%{files: [%{key: key, bucket: bucket, metadata: %{type: "audio/mp4"}}]})

      use_cassette("256_to_623_retrieve_transcript_call") do
        assert %{status: :ok, data: %{id: ^id}} = Transcription.start(meeting)
      end
    end
  end
end
