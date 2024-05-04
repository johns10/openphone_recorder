defmodule DiscussitWeb.OAuthTokenController do
  use DiscussitWeb, :controller

  def create(conn, params) do
    case ExOauth2Provider.Token.grant(params, otp_app: :discussit) do
      {:ok, access_token} ->
        render(conn, "show.json", access_token)

      {:error, error, http_status} ->
        render(conn)
    end
  end
end
