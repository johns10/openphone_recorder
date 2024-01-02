defmodule Discussit.TopicAnalyzer.Behaviour do
  @callback start_link(any()) :: {:ok, Pid.t()}
  @callback stop(Pid.t()) :: :ok
  @callback init_model(List.t(), Map.t(), String.t()) :: :ok
end
