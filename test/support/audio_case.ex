defmodule Discussit.AudioCase do
  use ExUnit.CaseTemplate

  setup do
    Application.put_env(:discussit, :audio_provider, Discussit.MockAudio)
    Mox.stub_with(Discussit.MockAudio, Discussit.StubAudio)

    :ok
  end
end
