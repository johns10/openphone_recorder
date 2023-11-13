defmodule Discussit.ClientCase do
  use ExUnit.CaseTemplate

  setup do
    Application.put_env(:discussit, :topic_analysis_client, Discussit.MockClient)
    Mox.stub_with(Discussit.MockClient, Discussit.StubClient)

    :ok
  end
end
