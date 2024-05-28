defmodule BoxImporterTest do
  use ExUnit.Case
  doctest BoxImporter
  alias BoxImporter.Files

  defp boxite_config do
    %BoxImporter.Config{
      access_token: "mSBEjhAzrXN7QieN5sNdYXLNfNg9RVVL",
      base_service_url: "https://api.box.com/2.0"
    }
  end

  # describe "file" do
  #   test "can get a file" do
  #     config = boxite_config()

  #     Files.get_file(config, "1540634070397")
  #   end
  # end

  describe "prescribed gen server" do
    test "can get a file" do
      {:ok, pid} =
        BoxImporter.start_link(
          access_token: "mSBEjhAzrXN7QieN5sNdYXLNfNg9RVVL",
          base_service_url: "https://api.box.com/2.0"
        )

      {:ok, _} = BoxImporter.get_file(pid, "1540634070397")
    end
  end
end
