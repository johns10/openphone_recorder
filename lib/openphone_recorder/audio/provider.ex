defmodule OpenphoneRecorder.Audio.Provider do
  def split(filename) do
    extname = String.slice(filename, -4, 4)
    left = Briefly.create!(extname: extname)
    right = Briefly.create!(extname: extname)

    System.cmd("ffmpeg", [
      "-y",
      "-i",
      filename,
      "-map_channel",
      "0.0.0",
      left,
      "-map_channel",
      "0.0.1",
      right
    ])
    |> case do
      {"", 0} ->
        {:ok, %{left: left, right: right}}

      {_, 1} ->
        {:error, "FFMPEG Execution failed"}
    end
  end
end
