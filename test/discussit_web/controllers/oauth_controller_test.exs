defmodule DiscussitWeb.OAuthControllerTest do
  use DiscussitWeb.ConnCase
  doctest DiscussitWeb.OAuthController
  alias DiscussitWeb.OAuthController

  describe "Oauth with user" do
    setup [:register_and_log_in_user]

    test "approval", %{conn: conn} do
      %{uid: uid, redirect_uri: redirect_uri} = create_application()

      conn =
        get(conn, ~p"/oauth/authorize",
          response_type: "code",
          client_id: uid,
          redirect_uri: redirect_uri,
          scope: "user: read"
        )

      assert Map.get(conn, :resp_body) =~ "Approve"

      conn =
        post(conn, ~p"/oauth/authorize",
          client_id: uid,
          approve: "true",
          state: Ecto.UUID.generate()
        )

      assert redirected_to(conn) =~ redirect_uri
    end

    test "deny", %{conn: conn} do
      %{uid: uid, redirect_uri: redirect_uri} = create_application()

      conn =
        get(conn, ~p"/oauth/authorize",
          response_type: "code",
          client_id: uid,
          redirect_uri: redirect_uri,
          scope: "user: read"
        )

      assert Map.get(conn, :resp_body) =~ "Approve"

      conn =
        post(conn, ~p"/oauth/authorize",
          client_id: uid,
          approve: "false",
          state: Ecto.UUID.generate()
        )

      assert redirected_to(conn) =~ redirect_uri <> "?error=access_denied"
    end


    test "already authorized", %{conn: conn} do
      %{uid: uid, redirect_uri: redirect_uri} = create_application()

      conn =
        get(conn, ~p"/oauth/authorize",
          response_type: "code",
          client_id: uid,
          redirect_uri: redirect_uri,
          scope: "user: read"
        )
        |> post( ~p"/oauth/authorize",
          client_id: uid,
          approve: "true",
          state: Ecto.UUID.generate()
        )
        |> get(~p"/oauth/authorize",
          response_type: "code",
          client_id: uid,
          redirect_uri: redirect_uri,
          scope: "user: read"
        )
    end
  end

  def create_application() do
    uid = Ecto.UUID.generate()

    %Discussit.OauthApplications.OauthApplication{
      name: Ecto.UUID.generate(),
      uid: uid,
      secret: Ecto.UUID.generate(),
      redirect_uri: "https://example.com/oauth/callback",
      scopes: "user: read statements: read"
    }
    |> Discussit.Repo.insert!()
  end
end
