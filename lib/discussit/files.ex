defmodule Discussit.Files do
  alias Discussit.Audio

  def handle_user_upload(%{path: path}, %{client_name: name}) do
    type = MIME.from_path(name)

    case type do
      "audio/mp4" ->
        key = "/meetings/#{UUID.uuid5(:url, name)}"
        bucket = Application.get_env(:discussit, :bucket)
        {:ok, _} = stream_upload(path, bucket, key)

        {:ok,
         %{
           metadata: %{name: name, type: type},
           bucket: bucket,
           key: key
         }}

      "video/mp4" ->
        # TODO put this behind a flame call
        with {:ok, output_path} <- Briefly.create(extname: ".m4a"),
             {:ok, output_path} <- Audio.mp4_to_m4a(path, output_path) do
          bucket = Application.get_env(:discussit, :bucket)
          audio_name = String.slice(name, 0..-5) <> ".m4a"
          key = "/meetings/#{UUID.uuid5(:url, audio_name)}"
          {:ok, _} = stream_upload(path, bucket, key)
          audio_type = MIME.from_path(audio_name)

          {:ok,
           %{
             metadata: %{name: audio_name, type: audio_type},
             bucket: bucket,
             key: key
           }}
        end
    end
  end

  defp stream_upload(path, bucket, key) do
    path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket, key)
    |> ExAws.request()
  end
end
