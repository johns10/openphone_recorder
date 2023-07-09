defmodule OpenphoneRecorderWeb.EventController do
  use OpenphoneRecorderWeb, :controller

  alias OpenphoneRecorder.Events
  alias OpenphoneRecorder.Events.Event
  alias OpenphoneRecorder.Events.Signature

  action_fallback OpenphoneRecorderWeb.FallbackController

  def index(conn, _params) do
    events = Events.list_events()
    render(conn, :index, events: events)
  end

  def create(conn, %{"account_id" => account_id, "event" => event_params}) do
    params = Map.put(event_params, "account_id", account_id)

    with {:ok, _signature} <- validate_request(conn),
         {:ok, %Event{} = event} <- Events.create_event(params) do
      conn
      |> put_status(:created)
      |> render(:show, event: event)
    end
  end

  def show(conn, %{"id" => id}) do
    event = Events.get_event!(id)
    render(conn, :show, event: event)
  end

  def update(conn, %{"id" => id, "event" => event_params}) do
    event = Events.get_event!(id)

    with {:ok, _signature} <- validate_request(conn),
         {:ok, %Event{} = event} <- Events.update_event(event, event_params) do
      render(conn, :show, event: event)
    end
  end

  def delete(conn, %{"id" => id}) do
    event = Events.get_event!(id)

    with {:ok, %Event{}} <- Events.delete_event(event) do
      send_resp(conn, :no_content, "")
    end
  end

  defp validate_request(conn) do
    secret = Application.get_env(:openphone_recorder, :signing_secret)
    incoming_signature = get_req_header(conn, "openphone-signature") |> Enum.at(0) || ""
    body = Map.get(conn.assigns, :raw_body) |> Enum.join()

    Signature.validate(incoming_signature, body, secret)
  end
end
