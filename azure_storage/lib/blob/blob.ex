defmodule AzureStorage.Blob do
  @moduledoc """
  All operations on Blobs.
  https://learn.microsoft.com/en-us/rest/api/storageservices/operations-on-blobs
  """
  alias AzureStorage.Container
  alias __MODULE__
  use AzureStorage.Request

  @enforce_keys [:name, :container]
  defstruct [
    :container,
    :name
  ]

  def new(%Container{} = container, name, _opts \\ []) do
    %Blob{
      container: container,
      name: name
    }
  end

  @doc """
  Creates a new blob in storage with the given data - for larger uploads
  prefer using Blocks.

  {:ok, %Blob{}) on success
  {:error, %Req.Response{}} on error

  https://learn.microsoft.com/en-us/rest/api/storageservices/put-blob
  """
  def put_blob(%Blob{} = blob, %Config{} = config, data, opts \\ []) when is_binary(data) do
    {_request, response} =
      Req.Request.new(
        method: :put,
        url:
          "#{build_base_url(config)}/#{URI.encode(blob.container.name)}/#{URI.encode(blob.name)}",
        headers: [
          {"content-length", byte_size(data) |> to_string},
          {"content-type", Keyword.get(opts, :content_type, "application/octet-stream")},
          {"x-ms-blob-type", Keyword.get(opts, :blob_type, "BlockBlob")}
        ],
        body: data
      )
      |> sign(config)
      |> Req.Request.run_request()

    case response.status do
      201 -> {:ok, blob}
      _ -> {:error, response}
    end
  end

  @doc """
  put_block uploads a Block in an uncommitted state. Note, 4mb or less in size for each block.
  https://learn.microsoft.com/en-us/rest/api/storageservices/put-block

  {:ok, block_id} on success - block id is a base64 encoded UUIDv4
  {:error, %Req.Response{}} on error
  """
  def put_block(%Blob{} = blob, %Config{} = config, block, opts \\ []) when is_binary(block) do
    block_id = UUID.uuid4(:hex)

    {_request, response} =
      Req.Request.new(
        method: :put,
        url:
          "#{build_base_url(config)}/#{URI.encode(blob.container.name)}/#{URI.encode(blob.name)}?comp=block&blockid=#{block_id}",
        headers: [
          {"content-length", byte_size(block) |> to_string},
          {"content-type", Keyword.get(opts, :content_type, "application/octet-stream")}
        ],
        body: block
      )
      |> sign(config)
      |> Req.Request.run_request()

    case response.status do
      201 -> {:ok, block_id}
      _ -> {:error, response}
    end
  end

  @doc """
  put_block_list allows a user to commit previously uploaded blocks to a blob.
  https://learn.microsoft.com/en-us/rest/api/storageservices/put-block-list

  {:ok, nil} on success
  {:error, %Req.Response{}} on error
  """
  def put_block_list(block_ids, %Blob{} = blob, %Config{} = config, _opts \\ [])
      when is_list(block_ids) do
    block_list =
      block_ids
      # don't want to mess with the order provided
      |> Enum.reverse()
      |> Enum.map_join("\n", fn block_id ->
        # typically you're supposed to base64 encode them - but for some reason when I do that it fails
        "<Latest>#{block_id}</Latest>"
      end)

    # I debated using an XML creation library for this, but we're doing so little with xml
    # really that I didn't want to add another dependency and have to vet it etc. Might as well
    # just write it by hand
    body = """
    <?xml version="1.0" encoding="utf-8"?>
    <BlockList>
      #{block_list}
    </BlockList>
    """

    {_request, response} =
      Req.Request.new(
        method: :put,
        url:
          "#{build_base_url(config)}/#{URI.encode(blob.container.name)}/#{URI.encode(blob.name)}?comp=blocklist",
        headers: [
          {"content-type", "text/plain charset=UTF-8"},
          {"content-length", byte_size(body) |> to_string}
        ],
        body: body
      )
      |> sign(config)
      |> Req.Request.run_request()

    case response.status do
      201 -> {:ok, blob}
      _ -> {:error, response}
    end
  end
end
