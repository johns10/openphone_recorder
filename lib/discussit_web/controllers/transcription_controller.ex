defmodule DiscussitWeb.TranscriptionController do
  alias Discussit.Calls
  require Logger
  use DiscussitWeb, :controller

  action_fallback(DiscussitWeb.FallbackController)

  def finish(conn, attrs) do
    {call_id, payload} = Map.pop(attrs, "call_id")
    {status, payload} = Map.pop(attrs, "status")

    call = Calls.get_call!(call_id, preloads: [:conversation])

    case status do
      "error" ->
        error = payload["error"]
        Logger.error("Transcription failed due to #{error}")
        Calls.update_call(call, %{transcription_ids: nil, status: :transcription_failed})

      "completed" ->
        Discussit.Transcription.Resolver.apply(call)
    end

    conn
    |> put_status(:created)
    |> render(:show, %{})
  end
end
