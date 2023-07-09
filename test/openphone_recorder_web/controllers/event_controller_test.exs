defmodule OpenphoneRecorderWeb.EventControllerTest do
  use OpenphoneRecorderWeb.ConnCase

  import OpenphoneRecorder.EventsFixtures
  import OpenphoneRecorder.AccountsFixtures

  alias OpenphoneRecorder.Events.Event

  @create_attrs %{
    payload: %{key: "Value"}
  }
  @update_attrs %{
    payload: %{new_key: "New value"}
  }
  @invalid_attrs %{payload: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp sign_request(conn, attrs) do
    timestamp = DateTime.now!("Etc/UTC") |> DateTime.to_unix()
    signing_secret = Application.get_env(:openphone_recorder, :signing_secret)
    body = Jason.encode!(attrs)
    signed_data = "#{timestamp}.#{body}"
    signing_key_bytes = Base.decode64!(signing_secret)

    hmac_digest =
      :crypto.mac(:hmac, :sha256, signing_key_bytes, signed_data)
      |> Base.encode64()

    conn
    |> put_req_header("openphone-signature", "test;stuff;#{timestamp};#{hmac_digest}")
    |> assign(:raw_body, [body])
  end

  describe "index" do
    test "lists all events", %{conn: conn} do
      conn = get(conn, ~p"/api/events")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create event" do
    test "renders event when data is valid", %{conn: conn} do
      account_id = account_fixture().id

      conn =
        conn
        |> sign_request(@create_attrs)
        |> post(~p"/api/events/#{account_id}", event: @create_attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/events/#{id}")

      assert %{
               "id" => ^id,
               "payload" => %{"key" => "Value"},
               "account_id" => ^account_id
             } = json_response(conn, 200)["data"]
    end

    # test "renders errors when data is invalid", %{conn: conn} do
    #   conn = conn |> sign_request(@invalid_attrs) |> post(~p"/api/events", event: @invalid_attrs)
    #   assert json_response(conn, 422)["errors"] != %{}
    # end
  end

  describe "update event" do
    setup [:create_event]

    test "renders event when data is valid", %{conn: conn, event: %Event{id: id} = event} do
      conn =
        conn
        |> sign_request(@update_attrs)
        |> put(~p"/api/events/#{event}", event: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/events/#{id}")

      assert %{
               "id" => ^id,
               "payload" => %{}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, event: event} do
      conn =
        conn
        |> sign_request(@invalid_attrs)
        |> put(~p"/api/events/#{event}", event: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete event" do
    setup [:create_event]

    test "deletes chosen event", %{conn: conn, event: event} do
      conn = delete(conn, ~p"/api/events/#{event}")
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, ~p"/api/events/#{event}")
      end)
    end
  end

  defp create_event(_) do
    event = event_fixture()
    %{event: event}
  end
end
