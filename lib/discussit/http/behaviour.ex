defmodule Discussit.HTTP.Behaviour do
  @moduledoc false
  @callback get(binary(), Map.t(), Keyword.t()) :: {:ok, Map.t()} | {:error, Map.t()}

  @callback put(binary(), any(), Map.t(), Keyword.t()) :: {:ok, Map.t()} | {:error, Map.t()}

  @callback post(binary(), any(), Map.t(), Keyword.t()) :: {:ok, Map.t()} | {:error, Map.t()}

  @callback delete(binary(), Map.t(), Keyword.t()) :: {:ok, Map.t()} | {:error, Map.t()}

  @callback start() :: :ok
end
