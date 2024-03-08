defmodule Discussit.Files.ConvertVideoTaskTest do
  use Discussit.DataCase
  use Discussit.AudioCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Discussit.Files.ConvertVideoTask
  alias Discussit.Files.ConvertVideoTask
  import Discussit.{AccountsFixtures, MeetingsFixtures}

  describe "ConvertVideoTask" do
    setup do
      key = "video"
      bucket = "discussit"
      account = account_fixture()

      meeting =
        meeting_fixture(%{
          files: [
            %{key: "audio", bucket: bucket, metadata: %{type: "audio/m4a"}},
            %{key: key, bucket: bucket, metadata: %{type: "video/mp4"}}
          ]
        })

      use_cassette("put_short_video") do
        "./test/support/fixtures/short_video.mp4"
        |> ExAws.S3.Upload.stream_file()
        |> ExAws.S3.upload(bucket, key)
        |> ExAws.request()
      end

      %{meeting: meeting, account: account}
    end

    test "works", %{meeting: meeting, account: account} do
      use_cassette("get_short_video") do
        %Oban.Job{args: %{"meeting_id" => meeting.id, "account_id" => account.id}}
        |> ConvertVideoTask.perform()
      end
    end
  end
end
