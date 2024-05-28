defmodule BoxImporterTest do
  use ExUnit.Case
  doctest BoxImporter
  alias BoxImporter.File

  defp boxite_config do
    %BoxImporter.Config{
      access_token: "v9Tza3T7a1qrOVBJPkPWiy8mShCtF3MX",
      base_service_url: "https://api.box.com/2.0"
    }
  end

  describe "file" do
    test "can get a file" do
      config = boxite_config()

      {:ok, nil} =
        File.get_file(config, "1540634070397")
    end
  end
end
