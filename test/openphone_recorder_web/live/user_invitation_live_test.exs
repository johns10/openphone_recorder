defmodule OpenphoneRecorderWeb.UserInivtationLiveTest do
  use OpenphoneRecorderWeb.ConnCase

  import Phoenix.LiveViewTest
  import OpenphoneRecorder.UsersFixtures

  alias OpenphoneRecorder.Users
  alias OpenphoneRecorder.Repo

  setup do
    %{user: user_fixture()}
  end

  describe "Accept Invitation" do
    test "renders invitation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/invitation/some-token")
      assert html =~ "Accept Invitation"
    end

    test "accepts the invite once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Users.deliver_user_invitation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/users/invitation/#{token}")

      result =
        lv
        |> form("#invitation_form", %{user: %{password: "asdfasdfasdf"}})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Invitation accepted"

      assert Users.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Users.UserToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/users/invitation/#{token}")

      result =
        lv
        |> form("#invitation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "User invitation link is invalid or it has expired"

      # when logged in
      {:ok, lv, _html} =
        build_conn()
        |> log_in_user(user)
        |> live(~p"/users/invitation/#{token}")

      result =
        lv
        |> form("#invitation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not accept invitation with invalid token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/invitation/invalid-token")

      {:ok, conn} =
        lv
        |> form("#invitation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "User invitation link is invalid or it has expired"

      refute Users.get_user!(user.id).confirmed_at
    end
  end
end
