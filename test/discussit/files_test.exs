defmodule Discussit.FilesTest do
  use Discussit.DataCase
  use Discussit.AudioCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Discussit.Files

  describe "Files" do
    test "handles user uploads" do
      path = Path.expand("./test/support/fixtures/short_video.m4a")

      use_cassette("upload_short_audio") do
        assert {:ok, _} =
                 Files.handle_user_upload(%{path: path}, %{client_name: "short_video.m4a"})
      end
    end

    test "handles and transcodes mp4 uploads" do
      path = Path.expand("./test/support/fixtures/short_video.mp4")

      use_cassette("upload_short_audio") do
        Files.handle_user_upload(%{path: path}, %{client_name: "short_video.mp4"})
      end
    end
  end
end
