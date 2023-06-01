defmodule OpenphoneRecorderWeb.SummarizerLiveTest do
  use OpenphoneRecorderWeb.ConnCase

  import Phoenix.LiveViewTest
  import OpenphoneRecorder.SummarizersFixtures

  @create_attrs %{prompt: "some prompt"}
  @update_attrs %{prompt: "some updated prompt"}
  @invalid_attrs %{prompt: nil}

  defp create_summarizer(_) do
    summarizer = summarizer_fixture()
    %{summarizer: summarizer}
  end

  describe "Index" do
    setup [:create_summarizer]

    test "lists all summarizers", %{conn: conn, summarizer: summarizer} do
      {:ok, _index_live, html} = live(conn, ~p"/summarizers")

      assert html =~ "Listing Summarizers"
      assert html =~ summarizer.prompt
    end

    test "saves new summarizer", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/summarizers")

      assert index_live |> element("a", "New Summarizer") |> render_click() =~
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
      assert html =~ "some prompt"
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
      assert html =~ "some updated prompt"
    end

    test "deletes summarizer in listing", %{conn: conn, summarizer: summarizer} do
      {:ok, index_live, _html} = live(conn, ~p"/summarizers")

      assert index_live |> element("#summarizers-#{summarizer.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#summarizers-#{summarizer.id}")
    end
  end

  describe "Show" do
    setup [:create_summarizer]

    test "displays summarizer", %{conn: conn, summarizer: summarizer} do
      {:ok, _show_live, html} = live(conn, ~p"/summarizers/#{summarizer}")

      assert html =~ "Show Summarizer"
      assert html =~ summarizer.prompt
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
      assert html =~ "some updated prompt"
    end
  end
end
