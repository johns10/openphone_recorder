defmodule Discussit.StubTopicAnalyzer do
  @behaviour Discussit.TopicAnalyzer.Behaviour

  @impl true
  def start(), do: {:ok, spawn(fn -> nil end)}

  @impl true
  def stop(_), do: :ok

  @impl true
  def start_server(_), do: {:ok, %{port: 999, status: :started}}
end
