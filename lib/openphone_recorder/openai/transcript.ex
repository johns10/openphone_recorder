defmodule OpenphoneRecorder.Openai.Transcript do
  alias OpenphoneRecorder.HTTP

  def create_transcript(%{file: file}, opts) do
    HTTP.post(url(), body(file, opts), headers())
  end

  defp body(file, opts) do
    response_format = Keyword.get(opts, :response_format, "verbose_json")

    {:multipart,
     [
       {"model", "whisper-1"},
       {"response_format", response_format},
       {:file, file}
     ]}
  end

  defp url(), do: OpenphoneRecorder.Openai.url() <> "/audio/transcriptions"

  defp headers(),
    do:
      OpenphoneRecorder.Openai.auth_header()
      |> Map.merge(%{"Content-Type" => "multipart/form-data"})
end
