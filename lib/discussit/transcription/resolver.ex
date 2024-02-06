defmodule Discussit.Transcription.Resolver do
  use GenServer
  require Logger
  alias Discussit.Transcription.Support
  alias Discussit.Calls
  alias Discussit.Transcription.AssemblyAI

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(_) do
    Process.send_after(self(), :check_transcripts, 1)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_transcripts, state) do
    calls = Calls.list_calls(filters: [status: :transcribing], preloads: [:conversation])

    calls
    |> Enum.filter(& &1.transcript_ids)
    |> Enum.reduce([], fn %{id: id, transcript_ids: ids} = call, acc ->
      {status, transcripts} = AssemblyAI.get_all_completed_transcripts(ids)

      case status do
        :ok ->
          [%{status: :ok, data: call, message: ""} | acc]

        :stop ->
          Logger.info("Call #{id} not ready to finish transcription")
          acc

        :error ->
          error =
            transcripts
            |> Enum.filter(&(&1["status"] == "error"))
            |> Enum.map(& &1["error"])
            |> Enum.join(" ")

          Logger.error("Transcription failed due to #{error}")
          Calls.update_call(call, %{transcription_ids: nil, status: :transcription_failed})
          acc
      end
    end)
    |> Enum.map(&Support.finish_transcribing(&1, account_id: &1.data.conversation.account_id))
    |> Enum.map(&Support.build_statement_attrs/1)
    |> Enum.map(&Support.create_statements/1)
    |> Enum.map(&Support.update_data/1)
    |> Enum.map(&Support.prepare_return/1)
    |> Enum.map(fn call ->
      DiscussitWeb.Endpoint.broadcast(
        "account_#{call.conversation.account_id}",
        "call_updated",
        call
      )
    end)

    Process.send_after(self(), :check_transcripts, 10_000)

    {:noreply, state}
  end
end
