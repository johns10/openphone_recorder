defmodule Discussit.StubAudio do
  @behaviour Discussit.Audio.Behaviour

  @impl true
  def split(_),
    do:
      {:ok,
       %{
         left: Path.expand("./test/support/fixtures/2channell.mp3"),
         right: Path.expand("./test/support/fixtures/2channelr.mp3")
       }}

  @impl true
  def duration(_), do: {:ok, 101.0248}
end
