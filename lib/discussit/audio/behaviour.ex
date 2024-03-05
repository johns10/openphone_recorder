defmodule Discussit.Audio.Behaviour do
  @moduledoc false
  @callback split(binary()) :: {:ok, Map.t()} | {:error, String.t()}
  @callback duration(binary()) :: {:ok, Float.t()} | {:error, String.t()}
  @callback mp4_to_m4a(String.t(), String.t()) :: {:ok, String.t() | {:error, String.t()}}
end
