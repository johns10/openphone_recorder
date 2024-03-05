defmodule Discussit.Audio.Provider do
  def split(filename) do
    extname = String.slice(filename, -4, 4)
    left = Briefly.create!(extname: extname)
    right = Briefly.create!(extname: extname)

    MuonTrap.cmd("ffmpeg", [
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

  def duration(filename) do
    MuonTrap.cmd("ffprobe", [
      filename,
      "-show_entries",
      "format=duration",
      "-v",
      "quiet",
      "-of",
      "csv=p=0"
    ])
    |> case do
      {duration, 0} when is_binary(duration) ->
        {:ok,
         duration
         |> String.replace("\n", "")
         |> String.to_float()}

      {_, 1} ->
        {:error, "ffprobe execution failed"}
    end
  end

  def mp4_to_m4a(input_filename, output_filename) do
    System.cmd("ffmpeg", ["-y", "-i", input_filename, "-vn", "-c:a", "copy", output_filename])
    |> case do
      {_, 0} -> {:ok, output_filename}
      _ -> {:error, "failed_to_transcode"}
    end
  end
end
