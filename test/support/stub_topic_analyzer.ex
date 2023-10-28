defmodule Discussit.StubTopicAnalyzer do
  @behaviour Discussit.TopicAnalyzer.Behaviour

  @impl true
  def init_model(topics, _embeddings, _account_id), do: {:ok, Enum.map(topics, fn _ -> 1 end)}

  @impl true
  def train_model(topics, _embeddings, _account_id), do: {:ok, Enum.map(topics, fn _ -> 1 end)}

  @impl true
  def get_topics(_account_id), do: {:ok, %{0 => "Topic 1", 1 => "Topic 2"}}
end
