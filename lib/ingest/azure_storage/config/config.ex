defmodule Ingest.AzureStorage.Config do
  # Optional
  defstruct [
    :account_name,
    :account_key,
    :account_connection_string,
    ssl: true,
    base_service_url: "blob.core.windows.net"
  ]
end
