defmodule Ingest.Uploaders.Azure do
  @moduledoc """
  Used for uploading to Azure Storage. While this is Blob storage, keep in mind that Gen2 is built
  on top of blob, so this will work just fine for Gen2 as long as things are formatted correctly in
  the filename (as a path)
  """
  @behaviour Phoenix.LiveView.UploadWriter
  alias AzureStorage.Container
  alias AzureStorage.Blob

  @impl true
  def init(opts) do
    # we try to put the caller in charge of ensuring no clashes with the file structure
    # we don't want to make many assumptions in the uploader
    filename = Keyword.fetch!(opts, :name)

    # we also pass the azure config and container from the caller since it's coming from the destinations
    # in our case and we don't want to deal with db calls here in this call
    config = Keyword.fetch!(opts, :config)
    container_name = Keyword.fetch!(opts, :container_name)

    blob = Container.new(container_name) |> Blob.new(filename)

    {:ok, %{chunk: 1, parts: [], config: config, blob: blob}}
  end

  @impl true
  def meta(state) do
    %{filename: state.filename, blob: state.blob}
  end

  @impl true
  def write_chunk(data, state) do
    case Blob.put_block(state.blob, state.config, data) do
      {:ok, block_id} -> {:ok, %{state | chunk: state.chunk + 1, parts: [block_id | state.parts]}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def close(state, reason) do
    case reason do
      :done ->
        case Blob.put_block_list(state.parts, state.blob, state.config) do
          {:ok, _list} -> {:ok, state}
          {:error, reason} -> {:error, reason}
        end

      _ ->
        {:error, reason}
    end
  end
end
