defmodule Ingest.Uploaders.Azure do
  @moduledoc """
  Used for uploading to Azure Storage. While this is Blob storage, keep in mind that Gen2 is built
  on top of blob, so this will work just fine for Gen2 as long as things are formatted correctly in
  the filename (as a path)
  """
  alias Ingest.Destinations.AzureConfig
  alias Ingest.Destinations
  alias Ingest.AzureStorage.Config
  alias Ingest.AzureStorage.Blob
  alias Ingest.AzureStorage.Container

  def init(%Destinations.Destination{} = destination, filename, state, opts \\ []) do
    original_filename = Keyword.get(opts, :original_filename, nil)
    %AzureConfig{} = d_config = destination.azure_config

    config = %Config{
      account_name: d_config.account_name,
      account_key: d_config.account_key,
      # base service URL is an optional field, so don't fail if we don't have it
      base_service_url: Map.get(d_config, :base_url),
      ssl: Map.get(d_config, :ssl, true)
    }

    # first we check if the object by filename and path exist in the container already
    # if it does, then we need to change the name and appened a - COPY (date) to the end of it
    filename =
      if Container.new(d_config.container)
         |> Blob.new("#{filename}")
         |> Blob.exists?(config) do
        "#{filename} - COPY #{DateTime.now!("UTC") |> DateTime.to_naive()}"
      else
        filename
      end

    filename =
      if original_filename do
        "#{original_filename} Supporting Data/ #{filename}"
      else
        filename
      end

    filename =
      if destination.additional_config do
        Enum.join([destination.additional_config["folder_name"], filename], "/")
      else
        filename
      end

    blob =
      Container.new(d_config.container)
      |> Blob.new("#{filename}")

    {:ok,
     {destination,
      state |> Map.put(:blob, blob) |> Map.put(:config, config) |> Map.put(:parts, [])}}
  end

  def upload_full_object(%Destinations.Destination{} = destination, filename, data, _opts \\ []) do
    %AzureConfig{} = d_config = destination.azure_config

    config = %Config{
      account_name: d_config.account_name,
      account_key: d_config.account_key,
      # base service URL is an optional field, so don't fail if we don't have it
      base_service_url: Map.get(d_config, :base_url),
      ssl: Map.get(d_config, :ssl, true)
    }

    filename =
      if destination.additional_config do
        Enum.join([destination.additional_config["folder_name"], filename], "/")
      else
        filename
      end

    Container.new(d_config.container)
    |> Blob.new("#{filename}")
    |> Blob.put_blob(config, data)
  end

  def upload_chunk(%Destinations.Destination{} = destination, _filename, state, data, _opts \\ []) do
    case Blob.put_block(state.blob, state.config, data) do
      {:ok, block_id} ->
        {:ok, {destination, %{state | parts: [block_id | state.parts]}}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def commit(%Destinations.Destination{} = destination, _filename, state, _opts \\ []) do
    {:ok, _location} = Blob.put_block_list(state.parts, state.blob, state.config)
    {:ok, {destination, state.blob.name}}
  end

  # update metadata is a little misnomer - we can't actually update the object once it's committed,
  # what we can do however is copy it to the same place and write the metadata to the newly copied
  # object
  def update_metadata(%Destinations.Destination{} = destination, path, metadata) do
    %AzureConfig{} = d_config = destination.azure_config

    path =
      if destination.additional_config do
        Enum.join([destination.additional_config["folder_name"], path], "/")
      else
        path
      end

    config =
      %Config{
        account_name: d_config.account_name,
        account_key: d_config.account_key,
        # base service URL is an optional field, so don't fail if we don't have it
        base_service_url: Map.get(d_config, :base_url),
        ssl: Map.get(d_config, :ssl, true)
      }

    Container.new(d_config.container)
    |> Blob.new(path)
    |> Blob.update_blob_metadata(config, metadata)
  end
end
