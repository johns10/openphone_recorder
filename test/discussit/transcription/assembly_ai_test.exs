defmodule Discussit.AssemblyAITest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Discussit.DataCase

  alias Discussit.Transcription.AssemblyAI

  import Discussit.AccountsFixtures

  describe "transcriber" do
    test "start_transcription works" do
      key = "256_to_623"
      bucket = "discussit"

      ExVCR.Config.filter_request_headers("Authorization")

      url =
        use_cassette("256_to_623_aws_call") do
          "./test/support/fixtures/256_to_623.mp3"
          |> ExAws.S3.Upload.stream_file()
          |> ExAws.S3.upload(bucket, key)
          |> ExAws.request()

          {:ok, url} =
            ExAws.Config.new(:s3)
            |> ExAws.S3.presigned_url(:get, bucket, key)

          url
        end

      use_cassette("256_to_623_aai_call") do
        assert {:ok, _id} = AssemblyAI.start_transcription(url)
      end
    end

    test "finish_transcription works" do
      account = account_fixture()

      use_cassette("256_to_623_retrieve_transcript_call") do
        assert {:ok, result} =
                 AssemblyAI.finish_transcription("b3e6e793-2c07-407a-b9a7-bfab893d2973",
                   account_id: account.id
                 )

        assert %{
                 segments: [
                   %{
                     "text" =>
                       "This is 256-65-8336 placing a call to 623-246-4213 this is 623-246-4213 receiving a call from 256-658-3236."
                   }
                   | _
                 ]
               } = result
      end
    end
  end
end
