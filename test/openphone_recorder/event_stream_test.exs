defmodule OpenphoneRecorder.EventStreamTest do
  use OpenphoneRecorder.DataCase
  use OpenphoneRecorder.HTTPCase
  use OpenphoneRecorder.AudioCase

  import Mox
  import OpenphoneRecorder.HTTPFixtures

  alias OpenphoneRecorder.EventStreamFixtures
  alias OpenphoneRecorder.Events
  alias OpenphoneRecorder.Events.Openphone.Projector

  @transcription_url "https://api.openai.com/v1/audio/transcriptions"

  @tag :integration
  describe "Stream" do
    test "streams" do
      OpenphoneRecorder.MockHTTP
      |> expect(:post, 16, fn @transcription_url, _, _, _ -> openai_speech() end)

      EventStreamFixtures.stream()
      |> Enum.take(100)
      |> Enum.map(fn params ->
        assert {:ok, _} =
          params.payload
          |> Events.cast_event()
          |> Projector.apply()
      end)
    end
  end
end
