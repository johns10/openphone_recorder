defmodule Discussit.StubClient do
  @behaviour Discussit.TopicAnalyzer.Client.Behaviour

  @impl true
  def start_link(_), do: {:ok, spawn(fn -> nil end)}

  @impl true
  def disconnect(), do: :ok

  @impl true
  def connect(_), do: :ok
end
