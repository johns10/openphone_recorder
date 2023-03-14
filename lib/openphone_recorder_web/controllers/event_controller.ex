defmodule OpenphoneRecorderWeb.EventController do
  use OpenphoneRecorderWeb, :controller

  alias OpenphoneRecorder.Events
  alias OpenphoneRecorder.Events.Event

  @signing_secret "TGNwdWZzbjhSVmRaQ0NBZTJtN3FRdU05QkF1amd1Z1E="

  action_fallback OpenphoneRecorderWeb.FallbackController

  def index(conn, _params) do
    events = Events.list_events()
    render(conn, :index, events: events)
  end

  def create(conn, event_params) do
    with true <- request_valid?(conn),
         {:ok, %Event{}} <- Events.create_event(event_params) do
      conn
      |> put_status(:created)
      |> send_resp(:no_content, "")
    end
  end

  def show(conn, %{"id" => id}) do
    event = Events.get_event!(id)
    render(conn, :show, event: event)
  end

  def update(conn, %{"id" => id, "event" => event_params}) do
    event = Events.get_event!(id)

    with true <- request_valid?(conn),
         {:ok, %Event{} = event} <- Events.update_event(event, event_params) do
      render(conn, :show, event: event)
    end
  end

  def delete(conn, %{"id" => id}) do
    event = Events.get_event!(id)

    with {:ok, %Event{}} <- Events.delete_event(event) do
    end
  end

  defp request_valid?(conn) do
    incoming_signature = get_req_header(conn, "openphone-signature") |> Enum.at(0)
    [_, _, timestamp, provided_digest] = String.split(incoming_signature, ";")
    body = Map.get(conn.assigns, :raw_body) |> Enum.join()

    signed_data = "#{timestamp}.#{body}"
    signing_key_bytes = Base.decode64!(@signing_secret)

    hmac_digest =
      :crypto.mac(:hmac, :sha256, signing_key_bytes, signed_data)
      |> Base.encode64()

    hmac_digest == incoming_signature
  end
end
