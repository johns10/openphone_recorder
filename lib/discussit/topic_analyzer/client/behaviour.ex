defmodule Discussit.TopicAnalyzer.Client.Behaviour do
  @callback start_link(Map.t()) :: {:ok, pid()}
  @callback connect(Integer.t()) :: :ok
  @callback disconnect() :: :ok
end
