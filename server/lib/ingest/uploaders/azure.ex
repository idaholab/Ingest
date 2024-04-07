defmodule Ingest.Uploaders.Azure do
  @moduledoc """
  Used for uploading to Azure Storage. While this is Blob storage, keep in mind that Gen2 is built
  on top of blob, so this will work just fine for Gen2 as long as things are formatted correctly in
  the filename (as a path)
  """
  alias Ingest.Destinations.AzureConfig
  alias Ingest.Destinations

  def init(%Destinations.Destination{} = destination, filename, state) do
    %AzureConfig{} = d_config = destination.azure_config

    config = %AzureStorage.Config{
      account_name: d_config.account_name,
      account_key: d_config.account_key,
      # base service URL is an optional field, so don't fail if we don't have it
      base_service_url: Map.get(d_config, :base_url),
      ssl: Map.get(d_config, :ssl, true)
    }

    blob =
      AzureStorage.Container.new(d_config.container)
      |> AzureStorage.Blob.new("#{d_config.path}/#{filename}")

    {:ok,
     {destination,
      state |> Map.put(:blob, blob) |> Map.put(:config, config) |> Map.put(:parts, [])}}
  end

  def upload_chunk(%Destinations.Destination{} = destination, filename, state, data) do
    case AzureStorage.Blob.put_block(state.blob, state.config, data) do
      {:ok, block_id} ->
        {:ok, {destination, %{state | parts: [block_id | state.parts]}}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def commit_blocklist(%Destinations.Destination{} = destination, filename, state) do
    AzureStorage.Blob.put_block_list(state.parts, state.blob, state.config)
  end
end
