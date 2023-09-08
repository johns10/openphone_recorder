defmodule Discussit.Transcription.OpenAI do
  require Logger

  def transcribe(path, duration, opts) do
    openai_config = Keyword.get(opts, :openai_config)
    account_id = Keyword.get(opts, :account_id)
    model = "whisper-1"
    opts = [model: model, response_format: "verbose_json"]

    case OpenAI.audio_transcription(path, opts, openai_config) do
      {:ok, %{segments: segments}} ->
        %{
          meta: %{duration: duration},
          model: model,
          product: :transcription,
          provider: :openai,
          account_id: account_id
        }
        |> Discussit.Usages.calculate_total()
        |> Discussit.Usages.create_usage()
        |> case do
          {:error, changeset} ->
            Logger.error("Failed to create transcription usage", changeset: changeset)

          _ ->
            nil
        end

        {:ok, segments}

      {:error, _} ->
        {:error, "Failed to transcribe"}
    end
  end
end
