defmodule OpenphoneRecorder.HTTPCase do
  use ExUnit.CaseTemplate

  setup do
    Application.put_env(:openphone_recorder, :http_provider, OpenphoneRecorder.MockHTTP)
    Mox.stub_with(OpenphoneRecorder.MockHTTP, OpenphoneRecorder.StubHTTP)

    :ok
  end
end
