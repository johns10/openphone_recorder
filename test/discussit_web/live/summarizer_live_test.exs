defmodule DiscussitWeb.SummarizerLiveTest do
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.SummarizersFixtures
  import Discussit.AccountsFixtures
  import Discussit.AccountUsersFixtures

  @create_attrs %{name: "some name", prompt: "some prompt"}
  @update_attrs %{name: "some updated name", prompt: "some updated prompt"}
  @invalid_attrs %{name: "name", prompt: nil}

  defp create_summarizer(_) do
    summarizer = summarizer_fixture()
    %{summarizer: summarizer}
  end

  defp account_setup(%{user: user}) do
    account = account_fixture()
    account_user_fixture(%{account_id: account.id, user_id: user.id})

    {:ok, user} =
      Discussit.Users.update_selected_account(user, %{selected_account_id: account.id})

    %{account: account, user: user}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :account_setup, :create_summarizer]

    test "lists all summarizers", %{conn: conn, summarizer: summarizer} do
      {:ok, _index_live, html} = live(conn, ~p"/summarizers")

      assert html =~ "Listing Summarizers"
      assert html =~ summarizer.name
    end

    test "saves new summarizer", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/summarizers")

      assert index_live |> element("a", "+") |> render_click() =~
               "New Summarizer"

      assert_patch(index_live, ~p"/summarizers/new")

      assert index_live
             |> form("#summarizer-form", summarizer: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#summarizer-form", summarizer: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/summarizers")

      html = render(index_live)
      assert html =~ "Summarizer created successfully"
      assert html =~ "some name"
    end

    test "updates summarizer in listing", %{conn: conn, summarizer: summarizer} do
      {:ok, index_live, _html} = live(conn, ~p"/summarizers")

      assert index_live |> element("#summarizers-#{summarizer.id} a", "Edit") |> render_click() =~
               "Edit Summarizer"

      assert_patch(index_live, ~p"/summarizers/#{summarizer}/edit")

      assert index_live
             |> form("#summarizer-form", summarizer: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#summarizer-form", summarizer: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/summarizers")

      html = render(index_live)
      assert html =~ "Summarizer updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes summarizer in listing", %{conn: conn, summarizer: summarizer} do
      {:ok, index_live, _html} = live(conn, ~p"/summarizers")

      assert index_live |> element("#summarizers-#{summarizer.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#summarizers-#{summarizer.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :account_setup, :create_summarizer]

    test "displays summarizer", %{conn: conn, summarizer: summarizer} do
      {:ok, _show_live, html} = live(conn, ~p"/summarizers/#{summarizer}")

      assert html =~ "Show Summarizer"
      assert html =~ summarizer.name
    end

    test "updates summarizer within modal", %{conn: conn, summarizer: summarizer} do
      {:ok, show_live, _html} = live(conn, ~p"/summarizers/#{summarizer}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Summarizer"

      assert_patch(show_live, ~p"/summarizers/#{summarizer}/show/edit")

      assert show_live
             |> form("#summarizer-form", summarizer: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#summarizer-form", summarizer: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/summarizers/#{summarizer}")

      html = render(show_live)
      assert html =~ "Summarizer updated successfully"
      assert html =~ "some updated name"
    end
  end
end
