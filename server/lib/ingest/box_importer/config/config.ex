defmodule BoxImporter.Config do
  # Optional
  defstruct [
    :access_token,
    base_service_url: "https://api.box.com/2.0"
  ]
end
