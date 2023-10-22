defmodule Discussit.Embeddings.ModelStatus do
  use Agent

  def start_link(_), do: Agent.start_link(fn -> :not_started end, name: __MODULE__)
  def get, do: Agent.get(__MODULE__, & &1)
  def set(state), do: Agent.update(__MODULE__, fn _ -> state end)
end
