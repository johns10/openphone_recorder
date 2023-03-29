defmodule OpenphoneRecorder.OpenaiTest do
  # use OpenphoneRecorder.HTTPCase
  use ExUnit.Case
  alias OpenphoneRecorder.Openai

  describe "Create Transcription" do
    @tag :integration

    test "creates a transcription" do
      assert {:ok, %HTTPoison.Response{}} =
               Openai.create_transcript(%{
                 file: Path.expand("./test/support/fixtures/hello.mp3")
               })
    end
  end
end
