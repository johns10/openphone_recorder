defmodule Discussit.TopicAnalyzerCase do
  use ExUnit.CaseTemplate

  setup do
    Application.put_env(:discussit, :topic_analysis_provider, Discussit.MockTopicAnalyzer)
    Mox.stub_with(Discussit.MockTopicAnalyzer, Discussit.StubTopicAnalyzer)

    :ok
  end
end
