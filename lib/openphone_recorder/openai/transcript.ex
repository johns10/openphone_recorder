defmodule OpenphoneRecorder.Openai.Transcript do
  alias OpenphoneRecorder.HTTP

  def create_transcript(%{file: file}) do
    HTTP.post(url(), body(file), headers())
  end

  defp body(file) do
    {:multipart,
     [
       {"model", "whisper-1"},
       {:file, file}
     ]}
  end

  defp url(), do: OpenphoneRecorder.Openai.url() <> "/audio/transcriptions"

  defp headers(),
    do:
      OpenphoneRecorder.Openai.auth_header()
      |> Map.merge(%{"Content-Type" => "multipart/form-data"})
end
