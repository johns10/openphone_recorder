defmodule DiscussitWeb.AccountLiveTest do
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.AccountsFixtures
  import Discussit.AccountUsersFixtures
  import Discussit.UsersFixtures
  import Discussit.AccountUsersFixtures

  @create_attrs %{name: "some name", plan: :free}
  @update_attrs %{name: "some updated name", plan: :basic}
  @invalid_attrs %{name: nil, plan: nil}

  defp create_account(_) do
    account = account_fixture()
    %{account: account}
  end

  describe "Index" do
    setup [:register_and_log_in_administrator, :create_account]

    test "lists all accounts", %{conn: conn, account: account} do
      {:ok, _index_live, html} = live(conn, ~p"/accounts")

      assert html =~ "Listing Accounts"
      assert html =~ account.name
    end

    test "saves new account", %{conn: conn, user: %{id: user_id}} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts/new")

      assert index_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#account-form", account: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accounts")

      html = render(index_live)
      assert html =~ "Account created successfully"
      assert html =~ "some name"
      assert Discussit.Accounts.list_accounts() |> Enum.find(&(&1.billing_user_id == user_id))
    end

    test "updates account in listing", %{conn: conn, account: account} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")
      other_user = user_fixture()
      account_user = account_user_fixture(%{user_id: other_user.id, account_id: account.id})

      assert index_live |> element("#accounts-#{account.id} a", "Edit") |> render_click() =~
               "Edit Account"

      assert_patch(index_live, ~p"/accounts/#{account}/edit")

      assert index_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      attrs = Map.put(@update_attrs, :billing_user_id, other_user.id)

      assert index_live
             |> form("#account-form", account: attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/accounts")

      html = render(index_live)
      assert html =~ "Account updated successfully"
      assert html =~ "some updated name"

      assert Discussit.Accounts.list_accounts()
             |> Enum.find(&(&1.billing_user_id == other_user.id))
    end

    test "deletes account in listing", %{conn: conn, account: account} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("#accounts-#{account.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#accounts-#{account.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_account]

    test "doesn't display account without access", %{conn: conn, account: account} do
      {:error,
       {:live_redirect, %{flash: %{"error" => "You cannot access this account"}, to: "/home"}}} =
        live(conn, ~p"/accounts/#{account}")
    end

    test "displays account with access", %{conn: conn, account: account, user: user} do
      account_user_fixture(%{user_id: user.id, account_id: account.id})
      {:ok, _show_live, html} = live(conn, ~p"/accounts/#{account}")

      assert html =~ "Show Account"
      assert html =~ account.name
    end

    test "updates account within modal", %{conn: conn, account: account, user: user} do
      account_user_fixture(%{user_id: user.id, account_id: account.id})
      {:ok, show_live, _html} = live(conn, ~p"/accounts/#{account}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Account"

      assert_patch(show_live, ~p"/accounts/#{account}/show/edit")

      assert show_live
             |> form("#account-form", account: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#account-form", account: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/accounts/#{account}")

      html = render(show_live)
      assert html =~ "Account updated successfully"
      assert html =~ "some updated name"
    end
  end
end
