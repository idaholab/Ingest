defmodule IngestWeb.ErrorJSONTest do
  use IngestWeb.ConnCase, async: false

  test "renders 404" do
    assert IngestWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert IngestWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
