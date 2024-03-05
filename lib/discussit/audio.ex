defmodule Discussit.Audio do
  @behaviour Discussit.Audio.Behaviour
  alias Discussit.Audio.Provider

  def provider(), do: Application.get_env(:discussit, :audio_provider, Provider)

  @impl true
  def split(file_name), do: provider().split(file_name)

  @impl true
  def duration(file_name), do: provider().duration(file_name)

  @impl true
  def mp4_to_m4a(input_filename, output_filename),
    do: provider().mp4_to_m4a(input_filename, output_filename)
end
