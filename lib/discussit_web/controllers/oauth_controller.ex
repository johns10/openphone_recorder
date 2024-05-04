defmodule DiscussitWeb.OAuthController do
  use DiscussitWeb, :controller
  alias ExOauth2Provider.AccessTokens
  alias Discussit.OauthAccessTokens.OauthAccessToken
  alias ExOauth2Provider.Authorization.Code

  def index(conn, params) do
    user = conn.assigns[:current_user]

    case ExOauth2Provider.Authorization.preauthorize(user, params, otp_app: :discussit) do
      {:ok, client, scopes} ->
        render(conn, "new.html", params: params, client: client, scopes: scopes)

      {:redirect, redirect_uri} ->
        redirect(conn, external: redirect_uri)

      {:native_redirect, %{code: code}} ->
        redirect(conn, to: ~p"/oauth/authorize/#{code}")

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> render("error.html", error: error)
    end
  end

  def create(conn, %{"approve" => "true", "client_id" => client_id, "state" => state}) do
    Code.authorize(
      conn.assigns[:current_user],
      %{
        "client_id" => client_id,
        "response_type" => "code",
        "state" => state
      },
      otp_app: :discussit,
      repo: Discussit.Repo
    )
    |> case do
      {:error, %{error: error, error_description: _}, status} ->
        conn
        |> put_status(status)
        |> render("error.html", error: error)

      {:redirect, redirect_uri} ->
        redirect(conn, external: redirect_uri)
    end
  end

  def create(conn, %{"approve" => "false", "client_id" => client_id, "state" => state}) do
    Code.deny(
      conn.assigns[:current_user],
      %{
        "client_id" => client_id,
        "response_type" => "code",
        "state" => state
      },
      otp_app: :discussit,
      repo: Discussit.Repo
    )
    |> case do
      {:error, %{error: error, error_description: _}, status} ->
        conn
        |> put_status(status)
        |> render("error.html", error: error)

      {:redirect, redirect_uri} ->
        redirect(conn, external: redirect_uri)
    end
  end

  def show(conn, %{"code" => code}) do
    case AccessTokens.get_by_token(code, otp_app: :discussit) do
      nil ->
        conn
        |> put_flash(:error, "Invalid or expired authorization code.")
        |> redirect(to: "/")

      %OauthAccessToken{} = token ->
        if AccessTokens.is_expired?(token) do
          conn
          |> put_flash(:error, "Authorization code has expired.")
          |> redirect(to: "/")
        else
          render(conn, "show.html", token: token)
        end
    end
  end
end
