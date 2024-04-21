defmodule DiscussitWeb.EventControllerTest do
  use DiscussitWeb.ConnCase

  import Discussit.AccountsFixtures

  alias Discussit.OpenphoneFixtures

  defp sign_request(conn, attrs) do
    timestamp = DateTime.now!("Etc/UTC") |> DateTime.to_unix()
    signing_secret = Application.get_env(:discussit, :signing_secret)
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

  # describe "index" do
  #   test "lists all events", %{conn: conn} do
  #     conn = get(conn, ~p"/api/events")
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  describe "create event" do
    setup %{conn: conn} do
      {:ok, conn: put_req_header(conn, "accept", "application/json")}
    end

    test "renders event when data is valid", %{conn: conn} do
      account_id = account_fixture().id

      payload =
        OpenphoneFixtures.message_received()
        |> Map.put("account_id", account_id)

      conn =
        conn
        |> sign_request(%{"key" => "value"})
        |> post(~p"/api/events/#{account_id}", payload)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/events/#{id}")

      assert %{
               "id" => ^id,
               "payload" => %{},
               "account_id" => ^account_id
             } = json_response(conn, 200)["data"]
    end

    # test "renders errors when data is invalid", %{conn: conn} do
    #   conn = conn |> sign_request(@invalid_attrs) |> post(~p"/api/events", event: @invalid_attrs)
    #   assert json_response(conn, 422)["errors"] != %{}
    # end
  end

  # describe "update event" do
  #   setup [:create_event]

  #   test "renders event when data is valid", %{conn: conn, event: %Event{id: id} = event} do
  #     account_id = account_fixture().id

  #     conn =
  #       conn
  #       |> sign_request(@update_attrs)
  #       |> put(~p"/api/events/#{account_id}/#{event}", account_id: account_id, key: "new_value")

  #     assert %{"id" => ^id} = json_response(conn, 200)["data"]

  #     conn = get(conn, ~p"/api/events/#{id}")

  #     assert %{
  #              "id" => ^id,
  #              "payload" => %{"key" => "new_value"}
  #            } = json_response(conn, 200)["data"]
  #   end

  # test "renders errors when data is invalid", %{conn: conn, event: event} do
  #   account_id = account_fixture().id

  #   conn =
  #     conn
  #     |> sign_request(@invalid_attrs)
  #     |> put(~p"/api/events/#{account_id}/#{event}", )

  #   assert json_response(conn, 422)["errors"] != %{}
  # end
  # end

  # defp create_event(_) do
  #   event = event_fixture()
  #   %{event: event}
  # end
end
