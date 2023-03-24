defmodule OpenphoneRecorder.Audio do
  @behaviour OpenphoneRecorder.Audio.Behaviour
  alias OpenphoneRecorder.Audio.Provider

  def provider(), do: Application.get_env(:openphone_recorder, :audio_provider, Provider)

  @impl true
  def split(file_name), do: provider().split(file_name)
end
