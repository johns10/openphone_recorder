defmodule OpenphoneRecorder.Audio.Behaviour do
  @moduledoc false
  @callback split(binary()) :: {:ok, Map.t()} | {:error, String.t()}
end
