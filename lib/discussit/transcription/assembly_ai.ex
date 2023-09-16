defmodule Discussit.Transcription.AssemblyAI do
  use Retry

  alias Discussit.HTTP
  alias Discussit.Usages

  require Logger

  @base_url "https://api.assemblyai.com/v2"

  def transcribe(link, opts) do
    body = %{"audio_url" => link, "speaker_labels" => "true"} |> Jason.encode!()
    updater = Keyword.get(opts, :update_transcript_id, fn _ -> nil end)

    with {:ok, %{status_code: 200, body: body}} <-
           HTTP.post(@base_url <> "/transcript", body, headers()),
         {:ok, %{"id" => id}} <- Jason.decode(body),
         updater.(id),
         {:ok, response} <- get_transcript(id),
         {:ok, _usage} <- create_usage(response, opts) do
      %{"utterances" => utterances, "audio_duration" => duration} = response
      {:ok, %{segments: utterances, duration: duration}}
    else
      {:ok, %{status_code: _}} ->
        Logger.error("Assembly AI call failed")
        {:error, "Assembly AI call failed"}

      {:error, reason} ->
        Logger.error("Assembly AI call failed: #{inspect(reason)}")
        {:error, "Assembly AI call failed"}
    end
  end

  defp get_transcript(id) do
    retry_while with: linear_backoff(500, 1) |> expiry(200_000) do
      url = @base_url <> "/transcript/#{id}"
      # Uncomment when you need a vcr
      # :timer.sleep(10000)

      with {:ok, %{status_code: 200, body: body}} <- HTTP.get(url, headers()),
           {:ok, json} <- Jason.decode(body) do
        case json do
          %{"status" => "completed"} = response ->
            {:halt, {:ok, response}}

          %{"status" => "error"} = result ->
            Logger.error(result["error"])
            {:halt, {:error, "failed to process"}}

          %{"status" => "queued"} ->
            {:cont, json}

          %{"status" => "processing"} ->
            {:cont, json}
        end
      end
    end
  end

  defp headers() do
    [{"Authorization", Application.get_env(:discussit, :aai_api_key)}]
  end

  defp create_usage(%{"audio_duration" => duration}, opts) do
    account_id = opts[:account_id] || raise("Account id required to create usage")

    %{
      meta: %{duration: duration},
      model: "assemblyai_default",
      product: :transcription,
      provider: :assemblyai,
      account_id: account_id
    }
    |> Usages.calculate_total()
    |> Usages.create_usage()
  end
end
