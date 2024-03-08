defmodule Discussit.Files.ConvertVideoTask do
  alias Discussit.Meetings

  use Oban.Worker,
    queue: :media

  @impl true
  def perform(%Oban.Job{args: %{"meeting_id" => meeting_id, "account_id" => _account_id}}) do
    meeting = %{files: files} = Meetings.get_meeting!(meeting_id)

    files =
      files
      |> Enum.map(fn
        %{metadata: %{"type" => "video/mp4", "name" => name} = metadata, bucket: bucket, key: key} =
            file ->
          {:ok, video_filename} = Briefly.create(extname: ".mp4")
          {:ok, audio_filename} = Briefly.create(extname: ".mpa")

          ExAws.S3.download_file(bucket, key, video_filename)
          |> ExAws.request()

          Discussit.Audio.mp4_to_m4a(video_filename, audio_filename)

          audio_filename
          |> ExAws.S3.Upload.stream_file()
          |> ExAws.S3.upload(bucket, key)
          |> ExAws.request()

          metadata =
            metadata
            |> Map.put("type", "audio/m4a")
            |> Map.put("name", String.replace(name, "mp4", "m4a"))

          file
          |> Map.put(:metadata, metadata)
          |> Map.from_struct()

        file ->
          file
          |> Map.from_struct()
      end)

    Meetings.update_meeting(meeting, %{files: files})
  end
end
