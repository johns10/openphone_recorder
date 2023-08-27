defmodule DiscussitWeb.UsageLiveTest do
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.UsagesFixtures

  defp create_usage(_) do
    usage = usage_fixture()
    %{usage: usage}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_usage]

    test "lists all usages", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/usages")

      assert html =~ "Listing Usages"
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_usage]

    test "displays usage", %{conn: conn, usage: usage} do
      {:ok, _show_live, html} = live(conn, ~p"/usages/#{usage}")

      assert html =~ "Show Usage"
    end
  end
end
