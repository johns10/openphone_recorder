defmodule DiscussitWeb.TranscriptionController do
  alias Discussit.Meetings
  alias Discussit.Calls
  alias Discussit.Transcription.Resolver
  require Logger
  use DiscussitWeb, :controller

  action_fallback(DiscussitWeb.FallbackController)

  def finish(conn, %{"call_id" => call_id, "status" => status}) do
    call = Calls.get_call!(call_id, preloads: [:conversation])

    case status do
      "error" ->
        Logger.error("Transcription failed")

        {:ok, call} =
          Calls.update_call(call, %{transcription_ids: nil, status: :transcription_failed})

        broadcast_call(call)

      "completed" ->
        call = Resolver.apply(call)
        broadcast_call(call)
    end

    conn
    |> put_status(:created)
    |> render(:show, %{})
  end

  def finish(conn, %{"meeting_id" => meeting_id, "status" => status, "account_id" => account_id}) do
    meeting = Meetings.get_meeting!(meeting_id)

    case status do
      "error" ->
        Logger.error("Transcription failed")

        {:ok, meeting} =
          Meetings.update_meeting(meeting, %{transcription_ids: nil, projector_status: :error})

        broadcast_meeting(meeting)

      "completed" ->
        Resolver.apply(meeting, account_id)
        broadcast_meeting(meeting)
    end

    conn
    |> put_status(:created)
    |> render(:show, %{})
  end

  defp broadcast_call(call) do
    DiscussitWeb.Endpoint.broadcast(
      "account_#{call.conversation.account_id}",
      "call_updated",
      call
    )
  end

  defp broadcast_meeting(%{user_id: user_id} = meeting) do
    DiscussitWeb.Endpoint.broadcast(
      "user_#{user_id}",
      "meeting_updated",
      meeting
    )
  end
end
