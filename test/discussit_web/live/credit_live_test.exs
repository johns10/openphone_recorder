defmodule DiscussitWeb.CreditLiveTest do
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.CreditsFixtures

  @create_attrs %{
    product_id: "some product_id",
    quantity: 120.5
  }
  @update_attrs %{
    product_id: "some updated product_id",
    quantity: 456.7
  }
  @invalid_attrs %{product_id: nil, quantity: nil}

  defp create_credit(_) do
    credit = credit_fixture()
    %{credit: credit}
  end

  describe "Index" do
    setup [:register_and_log_in_administrator, :user_setup, :create_credit]

    test "lists all credits", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/credits")

      assert html =~ "Listing Credits"
      assert html =~ "120.5"
    end

    test "saves new credit", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/credits")

      assert index_live |> element("a", "Buy Credit") |> render_click() =~
               "Buy Credit"

      assert_patch(index_live, ~p"/credits/new")

      assert index_live
             |> form("#credit-form", credit: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#credit-form", credit: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/credits")

      html = render(index_live)
      assert html =~ "Credit created successfully"
      assert html =~ "120.5"
    end

    # test "updates credit in listing", %{conn: conn, credit: credit} do
    #   {:ok, index_live, _html} = live(conn, ~p"/credits")

    #   assert index_live |> element("#credits-#{credit.id} a", "Edit") |> render_click() =~
    #            "Edit Credit"

    #   assert_patch(index_live, ~p"/credits/#{credit}/edit")

    #   assert index_live
    #          |> form("#credit-form", credit: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   assert index_live
    #          |> form("#credit-form", credit: @update_attrs)
    #          |> render_submit()

    #   assert_patch(index_live, ~p"/credits")

    #   html = render(index_live)
    #   assert html =~ "Credit updated successfully"
    # end

    # test "deletes credit in listing", %{conn: conn, credit: credit} do
    #   {:ok, index_live, _html} = live(conn, ~p"/credits")

    #   assert index_live |> element("#credits-#{credit.id} a", "Delete") |> render_click()
    #   refute has_element?(index_live, "#credits-#{credit.id}")
    # end
  end

  describe "Show" do
    setup [:register_and_log_in_administrator, :user_setup, :create_credit]

    test "displays credit", %{conn: conn, credit: credit} do
      {:ok, _show_live, html} = live(conn, ~p"/credits/#{credit}")

      assert html =~ "Show Credit"
      assert html =~ credit.product_id
    end

    test "updates credit within modal", %{conn: conn, credit: credit} do
      {:ok, show_live, _html} = live(conn, ~p"/credits/#{credit}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Credit"

      assert_patch(show_live, ~p"/credits/#{credit}/show/edit")

      assert show_live
             |> form("#credit-form", credit: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#credit-form", credit: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/credits/#{credit}")

      html = render(show_live)
      assert html =~ "Credit updated successfully"
      assert html =~ "some updated product_id"
    end
  end
end
