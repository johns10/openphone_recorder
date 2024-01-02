defmodule Discussit.StubTopicAnalyzer do
  @behaviour Discussit.TopicAnalyzer.Behaviour

  @impl true
  def start_link(_), do: {:ok, spawn(fn -> nil end)}

  @impl true
  def stop(_), do: :ok

  @impl true
  def init_model(_statements, _urls, path) do
    send(self(), {:done, []})
    File.touch!("#{path}/model.zip")
    :ok
  end
end
