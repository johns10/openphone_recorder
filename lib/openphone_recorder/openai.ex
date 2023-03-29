defmodule OpenphoneRecorder.Openai do
  def url(), do: "https://api.openai.com/v1"

  def auth_header,
    do: %{
      "Authorization" => "Bearer #{Application.get_env(:openphone_recorder, :openai_api_key)}"
    }

  defdelegate create_transcript(attrs, opts \\ []), to: OpenphoneRecorder.Openai.Transcript
end
