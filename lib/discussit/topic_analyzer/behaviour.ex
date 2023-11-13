defmodule Discussit.TopicAnalyzer.Behaviour do
  @callback start() :: {:ok, Pid.t()}
  @callback stop(Pid.t()) :: :ok
  @callback start_server(Pid.t()) :: {:ok, Map.t()}
  @callback stop_server(Pid.t()) :: {:ok, Pid.t()}
end
