defmodule Discussit.Transcription.Behaviour do
  @moduledoc false
  @callback transcribe(binary()) :: {:ok, Map.t()} | {:error, String.t()}
end
