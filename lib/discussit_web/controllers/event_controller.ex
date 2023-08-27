defmodule DiscussitWeb.EventController do
  use DiscussitWeb, :controller

  alias Discussit.Accounts
  alias Discussit.Events
  alias Discussit.Events.Consumer
  alias Discussit.Events.Event
  alias Discussit.Events.Signature

  action_fallback(DiscussitWeb.FallbackController)

  def index(conn, _params) do
    events = Events.list_events()
    render(conn, :index, events: events)
  end

  def create(conn, attrs) do
    {account_id, payload} = Map.pop(attrs, "account_id")

    with {:ok, _signature} <- validate_request(conn, account_id),
         {:ok, %Event{} = event} <-
           Events.create_event(%{
             account_id: account_id,
             payload: payload,
             skipped: false,
             processed: false
           }) do
      Consumer.start()

      conn
      |> put_status(:created)
      |> render(:show, event: event)
    end
  end

  def show(conn, %{"id" => id}) do
    event = Events.get_event!(id)
    render(conn, :show, event: event)
  end

  def update(conn, attrs) do
    {id, attrs} = Map.pop(attrs, "id")
    event = Events.get_event!(id)
    {account_id, payload} = Map.pop(attrs, "account_id")

    with {:ok, _signature} <- validate_request(conn, account_id),
         {:ok, %Event{} = event} <-
           Events.update_event(event, %{account_id: account_id, payload: payload}) do
      render(conn, :show, event: event)
    end
  end

  def delete(conn, %{"id" => id}) do
    event = Events.get_event!(id)

    with {:ok, %Event{}} <- Events.delete_event(event) do
      send_resp(conn, :no_content, "")
    end
  end

  defp validate_request(conn, account_id) do
    %{openphone_signing_secret: secret} = Accounts.get_account!(account_id)
    incoming_signature = get_req_header(conn, "openphone-signature") |> Enum.at(0) || ""
    body = Map.get(conn.assigns, :raw_body) |> Enum.join()

    Signature.validate(incoming_signature, body, secret)
  end
end
