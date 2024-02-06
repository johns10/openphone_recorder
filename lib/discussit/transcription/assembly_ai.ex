defmodule Discussit.Transcription.AssemblyAI do
  use Retry

  alias Discussit.HTTP
  alias Discussit.Usages

  require Logger

  @base_url "https://api.assemblyai.com/v2"

  def transcribe(link, opts) do
    updater = Keyword.get(opts, :update_transcript_id, fn _ -> nil end)

    with {:ok, id} <- start_transcription(link),
         updater.(id),
         {:ok, %{"utterances" => utterances, "audio_duration" => duration}} <-
           finish_transcription(id, opts) do
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

  def start_transcription(link, opts \\ %{}) do
    body = Map.put(opts, :audio_url, link) |> Jason.encode!()
    url = @base_url <> "/transcript"

    with {:ok, %{status_code: 200, body: body}} <- HTTP.post(url, body, headers()),
         {:ok, %{"id" => id}} <- Jason.decode(body) do
      {:ok, id}
    end
  end

  def finish_transcription(id, opts) do
    with {:ok, response} <- wait_until_transcription_completes(id),
         {:ok, _usage} <- create_usage(response, opts) do
      %{"utterances" => utterances, "audio_duration" => duration} = response
      {:ok, %{segments: utterances, duration: duration}}
    end
  end

  def get_all_completed_transcripts(ids) do
    Enum.reduce_while(ids, {:ok, []}, fn id, {status, acc} ->
      case get_transcript(id) do
        {:ok, %{"status" => "completed"} = result} ->
          {:cont, {status, [result | acc]}}

        {:ok, %{"status" => "error"} = result} ->
          Logger.warn("Transcript #{id}", result: result)
          {:cont, {:error, [result | acc]}}

        {:ok, %{"status" => "processing"} = result} ->
          {:cont, {:stop, [result | acc]}}

        _ ->
          {:halt, {:stop, acc}}
      end
    end)
  end

  def get_transcript(id) do
    url = @base_url <> "/transcript/#{id}"

    with {:ok, %{status_code: 200, body: body}} <- HTTP.get(url, headers()),
         {:ok, json} <- Jason.decode(body) do
      {:ok, json}
    end
  end

  defp wait_until_transcription_completes(id) do
    retry_while with: linear_backoff(500, 1) |> expiry(100_000_000) do
      with {:ok, json} <- get_transcript(id) do
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
