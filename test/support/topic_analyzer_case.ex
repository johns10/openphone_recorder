defmodule Discussit.TopicAnalyzerCase do
  use ExUnit.CaseTemplate

  setup _ do
    Mox.stub_with(Discussit.MockTopicAnalyzer, Discussit.StubTopicAnalyzer)
    Application.put_env(:discussit, :topic_analysis_server, Discussit.MockTopicAnalyzer)

    :ok
  end
end
