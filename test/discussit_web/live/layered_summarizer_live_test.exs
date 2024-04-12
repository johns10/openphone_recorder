defmodule DiscussitWeb.LayeredSummarizerLiveTest do
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.LayeredSummarizersFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_layered_summarizer(_) do
    layered_summarizer = layered_summarizer_fixture()
    %{layered_summarizer: layered_summarizer}
  end

  describe "Index" do
    setup [:create_layered_summarizer]

    test "lists all layered_summarizers", %{conn: conn, layered_summarizer: layered_summarizer} do
      {:ok, _index_live, html} = live(conn, ~p"/layered_summarizers")

      assert html =~ "Listing Layered summarizers"
      assert html =~ layered_summarizer.name
    end

    test "saves new layered_summarizer", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/layered_summarizers")

      assert index_live |> element("a", "New Layered summarizer") |> render_click() =~
               "New Layered summarizer"

      assert_patch(index_live, ~p"/layered_summarizers/new")

      assert index_live
             |> form("#layered_summarizer-form", layered_summarizer: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#layered_summarizer-form", layered_summarizer: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/layered_summarizers")

      html = render(index_live)
      assert html =~ "Layered summarizer created successfully"
      assert html =~ "some name"
    end

    test "updates layered_summarizer in listing", %{conn: conn, layered_summarizer: layered_summarizer} do
      {:ok, index_live, _html} = live(conn, ~p"/layered_summarizers")

      assert index_live |> element("#layered_summarizers-#{layered_summarizer.id} a", "Edit") |> render_click() =~
               "Edit Layered summarizer"

      assert_patch(index_live, ~p"/layered_summarizers/#{layered_summarizer}/edit")

      assert index_live
             |> form("#layered_summarizer-form", layered_summarizer: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#layered_summarizer-form", layered_summarizer: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/layered_summarizers")

      html = render(index_live)
      assert html =~ "Layered summarizer updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes layered_summarizer in listing", %{conn: conn, layered_summarizer: layered_summarizer} do
      {:ok, index_live, _html} = live(conn, ~p"/layered_summarizers")

      assert index_live |> element("#layered_summarizers-#{layered_summarizer.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#layered_summarizers-#{layered_summarizer.id}")
    end
  end

  describe "Show" do
    setup [:create_layered_summarizer]

    test "displays layered_summarizer", %{conn: conn, layered_summarizer: layered_summarizer} do
      {:ok, _show_live, html} = live(conn, ~p"/layered_summarizers/#{layered_summarizer}")

      assert html =~ "Show Layered summarizer"
      assert html =~ layered_summarizer.name
    end

    test "updates layered_summarizer within modal", %{conn: conn, layered_summarizer: layered_summarizer} do
      {:ok, show_live, _html} = live(conn, ~p"/layered_summarizers/#{layered_summarizer}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Layered summarizer"

      assert_patch(show_live, ~p"/layered_summarizers/#{layered_summarizer}/show/edit")

      assert show_live
             |> form("#layered_summarizer-form", layered_summarizer: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#layered_summarizer-form", layered_summarizer: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/layered_summarizers/#{layered_summarizer}")

      html = render(show_live)
      assert html =~ "Layered summarizer updated successfully"
      assert html =~ "some updated name"
    end
  end
end
