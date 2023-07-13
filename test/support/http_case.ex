defmodule Discussit.HTTPCase do
  use ExUnit.CaseTemplate

  setup do
    Application.put_env(:discussit, :http_provider, Discussit.MockHTTP)
    Mox.stub_with(Discussit.MockHTTP, Discussit.StubHTTP)

    :ok
  end
end
