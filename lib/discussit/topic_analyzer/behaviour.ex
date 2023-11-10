defmodule Discussit.TopicAnalyzer.Behaviour do
  @callback init_model(List.t(), List.t(), Integer.t()) :: List.t()
  @callback train_model(List.t(), List.t(), Integer.t()) :: List.t()
  @callback get_topics(Integer.t()) :: Map.t()
end
