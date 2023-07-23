defmodule Discussit.EventStreamTest do
  use Discussit.DataCase
  use Discussit.HTTPCase
  use Discussit.AudioCase

  import Mox
  import Discussit.HTTPFixtures
  import Discussit.AccountsFixtures

  alias Discussit.EventStreamFixtures
  alias Discussit.Events
  alias Discussit.Events.Openphone.Projector

  @transcription_url "https://api.openai.com/v1/audio/transcriptions"

  @tag :integration
  describe "Stream" do
    test "streams" do
      account = account_fixture()

      Discussit.MockHTTP
      |> expect(:post, 16, fn @transcription_url, _, _, _ -> openai_speech() end)

      EventStreamFixtures.stream()
      |> Enum.take(100)
      |> Enum.map(fn params ->
        assert {:ok, _} =
                 params.payload
                 |> Events.cast_event()
                 |> Projector.apply(account.id)
      end)
    end
  end
end
