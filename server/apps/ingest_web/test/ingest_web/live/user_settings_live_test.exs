defmodule IngestWeb.UserSettingsLiveTest do
  use IngestWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "Settings page" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
