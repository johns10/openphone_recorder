defmodule DiscussitWeb.ErrorJSONTest do
  use DiscussitWeb.ConnCase, async: true

  test "renders 404" do
    assert DiscussitWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert DiscussitWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
