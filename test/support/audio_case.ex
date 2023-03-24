defmodule OpenphoneRecorder.AudioCase do
  use ExUnit.CaseTemplate

  setup do
    Application.put_env(:openphone_recorder, :audio_provider, OpenphoneRecorder.MockAudio)
    Mox.stub_with(OpenphoneRecorder.MockAudio, OpenphoneRecorder.StubAudio)

    :ok
  end
end
