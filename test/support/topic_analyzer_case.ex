defmodule Discussit.TopicAnalyzerCase do
  use ExUnit.CaseTemplate

  setup _ do
    Application.put_env(:discussit, :topic_analysis_server, Discussit.MockTopicAnalyzer)
    Mox.stub_with(Discussit.MockTopicAnalyzer, Discussit.StubTopicAnalyzer)

    :ok
  end
end
