defmodule Discussit.AssemblyAITest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Discussit.DataCase

  alias Discussit.Transcription.AssemblyAI

  import Discussit.AccountsFixtures

  describe "transcriber" do
    @tag timeout: 200_000
    test "does base case" do
      key = "key"
      bucket = "discussit"
      account = account_fixture()

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("aai_transcription") do
        "./test/support/fixtures/256_to_623.mp3"
        |> ExAws.S3.Upload.stream_file()
        |> ExAws.S3.upload(bucket, key)
        |> ExAws.request()

        {:ok, url} =
          ExAws.Config.new(:s3)
          |> ExAws.S3.presigned_url(:get, bucket, key)

        assert {:ok,
                %{
                  segments: [%{"text" => "This is 256-65-8336 placing a call" <> _}],
                  duration: _
                }} = AssemblyAI.transcribe(url, account_id: account.id)
      end
    end
  end
end
