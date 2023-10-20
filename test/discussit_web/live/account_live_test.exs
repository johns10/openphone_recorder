defmodule DiscussitWeb.AccountLiveTest do
  use DiscussitWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Phoenix.LiveViewTest
  import Discussit.AccountUsersFixtures
  import Discussit.UsersFixtures
  import Discussit.AccountUsersFixtures
  alias Discussit.Accounts

  @create_attrs %{name: "some name", plan: :free, enable_embeddings: false}
  @update_attrs %{name: "some updated name", plan: :basic, enable_embeddings: true}
  @invalid_attrs %{name: nil, plan: nil}

  describe "Index" do
    setup [:register_and_log_in_administrator, :user_setup]

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

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("create_stripe_customer") do
        assert index_live
               |> form("#account-form", account: @create_attrs)
               |> render_submit()
      end

      assert_patch(index_live, ~p"/accounts")

      html = render(index_live)
      assert html =~ "Account created successfully"
      assert html =~ "some name"

      account =
        Discussit.Accounts.list_accounts()
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.at(-1)

      assert account.billing_user_id == user_id
      assert account.stripe_customer_id

      use_cassette("delete_stripe_customer") do
        Stripe.Customer.delete(account.stripe_customer_id)
      end
    end

    test "updates account in listing", %{conn: conn, account: account} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")
      other_user = user_fixture()
      account_user_fixture(%{user_id: other_user.id, account_id: account.id})

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("update_account_index") do
        {:ok, %{id: id}} = Stripe.Customer.create(%{email: other_user.email, name: account.name})

        {:ok, account} = Accounts.update_account(account, %{stripe_customer_id: id})

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

        assert account =
                 Discussit.Accounts.list_accounts()
                 |> Enum.find(&(&1.billing_user_id == other_user.id))

        assert account.stripe_customer_id

        Stripe.Customer.delete(account.stripe_customer_id)
      end
    end

    test "deletes account in listing", %{conn: conn, account: account} do
      {:ok, index_live, _html} = live(conn, ~p"/accounts")

      assert index_live |> element("#accounts-#{account.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#accounts-#{account.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :user_setup]

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
      assert html =~ "Embeddings Disabled"
    end

    test "updates account within modal", %{conn: conn, account: account, user: user} do
      account_user_fixture(%{user_id: user.id, account_id: account.id})
      other_user = user_fixture()
      account_user_fixture(%{user_id: other_user.id, account_id: account.id})

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("update_account_show") do
        {:ok, %{id: id}} = Stripe.Customer.create(%{email: other_user.email, name: account.name})
        {:ok, account} = Accounts.update_account(account, %{stripe_customer_id: id})
        {:ok, show_live, _html} = live(conn, ~p"/accounts/#{account}")

        assert show_live |> element("a", "Edit") |> render_click() =~
                 "Edit Account"

        assert_patch(show_live, ~p"/accounts/#{account}/show/edit")

        assert show_live
               |> form("#account-form", account: @invalid_attrs)
               |> render_change() =~ "can&#39;t be blank"

        attrs = Map.put(@update_attrs, :billing_user_id, other_user.id)

        assert show_live
               |> form("#account-form", account: attrs)
               |> render_submit()

        assert_patch(show_live, ~p"/accounts/#{account}", 5000)

        html = render(show_live)
        assert html =~ "Account updated successfully"
        assert html =~ "some updated name"
        assert html =~ "Embeddings Enabled"
        Stripe.Customer.delete(account.stripe_customer_id)
      end
    end

    test "adds a payment method", %{conn: conn, account: account, user: user} do
      account_user_fixture(%{user_id: user.id, account_id: account.id})

      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("add_payment_method") do
        {:ok, %{id: id}} = Stripe.Customer.create(%{email: user.email, name: account.name})
        {:ok, account} = Accounts.update_account(account, %{stripe_customer_id: id})
        {:ok, show_live, _html} = live(conn, ~p"/accounts/#{account}")

        assert show_live |> element("a", "Add Payment Method") |> render_click() =~
                 "Add a Credit Card"
      end
    end
  end
end
