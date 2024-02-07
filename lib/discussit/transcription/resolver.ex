defmodule Discussit.Transcription.Resolver do
  require Logger
  alias Discussit.Calls.Call
  alias Discussit.Transcription.Support
  alias Discussit.Calls
  alias Discussit.Meetings
  alias Discussit.Transcription.AssemblyAI

  def apply(%Call{transcript_ids: ids, conversation: %{account_id: account_id}} = call) do
    {status, transcripts} = AssemblyAI.get_all_completed_transcripts(ids)

    case status do
      :ok ->
        Discussit.Transcription.finish(call, account_id)

      :stop ->
        nil

      :error ->
        error =
          transcripts
          |> Enum.filter(&(&1["status"] == "error"))
          |> Enum.map(& &1["error"])
          |> Enum.join(" ")

        Logger.error("Transcription failed due to #{error}")
        Calls.update_call(call, %{transcription_ids: nil, status: :transcription_failed})
    end
  end

  def audit_meetings(meetings) do
    meetings
    |> Enum.filter(& &1.transcript_ids)
    |> Enum.filter(&(&1.projector_status == :in_progress))
    |> Enum.reduce([], fn %{id: id, transcript_ids: ids} = meeting, acc ->
      {status, transcripts} = AssemblyAI.get_all_completed_transcripts(ids)

      case status do
        :ok ->
          [%{status: :ok, data: meeting, message: ""} | acc]

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

          Meetings.update_meeting(meeting, %{
            transcription_ids: nil,
            projector_status: :transcription_failed
          })

          acc
      end
    end)
    |> Enum.map(&Support.finish_transcribing/1)
    |> Enum.map(&Support.build_statement_attrs/1)
    |> Enum.map(&Support.create_statements/1)
    |> Enum.map(&Support.update_data/1)
    |> Enum.map(&Support.prepare_return/1)
    |> Enum.map(fn meeting ->
      DiscussitWeb.Endpoint.broadcast(
        "user_#{meeting.user_id}",
        "meeting_updated",
        meeting
      )
    end)
  end

  def audit_calls() do
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
  end
end
