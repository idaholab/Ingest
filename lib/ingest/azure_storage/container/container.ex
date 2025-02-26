defmodule Ingest.AzureStorage.Container do
  @moduledoc """
  All operations and program flow for the Containers object in Azure storage.
  https://learn.microsoft.com/en-us/rest/api/storageservices/operations-on-containers
  """
  alias Ingest.AzureStorage.Config
  alias __MODULE__

  use Ingest.AzureStorage.Request
  import SweetXml

  @enforce_keys [:name]
  defstruct [
    :name
  ]

  @doc """
  new simply creates a new Container struct with the given arguments, but does not create
  it in the storage account.
  """
  def new(name) do
    # can eventually add checks to make sure the container exists, and the name is valid etc.
    # options to create if it does not exist etc.
    %Container{
      name: name
    }
  end

  def list_blobs(%Container{} = container, %Config{} = config, prefix \\ nil) do
    {_request, response} =
      Req.Request.new(
        method: :get,
        url:
          if prefix do
            "#{build_base_url(config)}/#{URI.encode(container.name)}?restype=container&comp=list&prefix=#{URI.encode(prefix)}"
          else
            "#{build_base_url(config)}/#{URI.encode(container.name)}?restype=container&comp=list&"
          end
      )
      |> sign(config)
      |> Req.Request.run_request()

    case response.status do
      200 ->
        {:ok,
         response.body
         |> xmap(
           blobs: [
             ~x"//Blobs/Blob"l,
             name: ~x"./Name/text()",
             properties: [
               ~x"./Properties"l,
               creation_time: ~x"./Creation-Time/text()",
               last_modified: ~x"./Last-Modified/text()",
               etag: ~x"./Etag/text()",
               owner: ~x"./Owner/text()",
               group: ~x"./Group/text()",
               permissions: ~x"./Permissions/text()",
               acl: ~x"./Acl/text()",
               resource_type: ~x"./ResourceType/text()",
               content_length: ~x"./Content-Length/text()",
               content_type: ~x"./Content-Type/text()",
               content_encoding: ~x"./Content-Encoding/text()",
               content_md5: ~x"./Content-MD5/text()",
               access_tier: ~x"./AccessTier/text()",
               blob_type: ~x"./BlobType/text()",
               deleted_time: ~x"./DeletedTime/text()"
             ]
           ]
         )}

      _ ->
        {:error, response}
    end
  end
end
