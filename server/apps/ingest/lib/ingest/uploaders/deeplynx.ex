defmodule Ingest.Uploaders.DeepLynx do
  @moduledoc """
  Used for uploading to DeepLynx storage.
  """

  alias Ingest.Destinations.DeepLynxConfig
  alias Ingest.Destinations

  def init(%Destinations.Destination{} = destination, filename, state, opts \\ []) do
    %DeepLynxConfig{} = d_config = destination.deeplynx_config
    original_filename = Keyword.get(opts, :original_filename, nil)
    filename =
      if original_filename do
        "#{original_filename} Supporting Data/ #{filename}"
      else
        filename
      end
    base_url = Keyword.get(opts, :base_url, nil)
    container = Keyword.get(opts, :container, nil)
    datasource = Keyword.get(opts, :datasource, nil)
    file_key = ShortUUID.encode(UUID.uuid4())

    {:ok,
     {destination,
      state
      |> Map.put(:base_url, base_url)
      |> Map.put(:container, container)
      |> Map.put(:datasource, datasource)
      |> Map.put(:file_key, file_key)
      |> Map.put(:filename, filename)
      |> Map.put(:parts, [])}}
  end

  def update_metadata(%Destinations.Destination{} = destination, file_id, metadata) do
    %DeepLynxConfig{} = d_config = destination.deeplynx_config
    config = %DeepLynxConfig{
      base_url: d_config.base_url,
      access_key_id: d_config.access_key_id,
      secret_access_key: d_config.secret_access_key,
      container: d_config.container,
      datasource: d_config.datasource
    }

    request = Req.new(
      base_url: config.base_url,
      auth: {:basic, "#{config.access_key_id}:#{config.secret_access_key}"},
      headers: [{"content-type", "application/octet-stream"}]
    )

    response = Req.post!(request, url: "/containers/#{config.container}/import/datasources/#{config.datasource}/#{file_id}/metadata", body: metadata)

    case response do
      %{status: 200} ->
        {:ok, response.body}
      %{status: status} ->
        {:error, status}
    end
  end

  def upload_full_object(%Destinations.Destination{} = destination, data) do
    %DeepLynxConfig{} = d_config = destination.deeplynx_config
    config = %DeepLynxConfig{
      base_url: d_config.base_url,
      access_key_id: d_config.access_key_id,
      secret_access_key: d_config.secret_access_key,
      container: d_config.container,
      datasource: d_config.datasource
    }

    request = Req.new(
      base_url: config.base_url,
      auth: {:basic, "#{config.access_key_id}:#{config.secret_access_key}"},
      headers: [{"content-type", "application/octet-stream"}]
    )

    response = Req.post!(request, url: "/containers/#{config.container}/import/datasources/#{config.datasource}/files", body: data)

    case response do
      %{status: 200} ->
        {:ok, response.body.file_id}
      %{status: status} ->
        {:error, status}
    end
  end

  def upload_chunk(%Destinations.Destination{} = destination, _filename, state, data, _opts \\ []) do
    %DeepLynxConfig{} = d_config = destination.deeplynx_config
    config = %DeepLynxConfig{
      base_url: d_config.base_url,
      access_key_id: d_config.access_key_id,
      secret_access_key: d_config.secret_access_key,
      container: d_config.container,
      datasource: d_config.datasource
    }
    block_id = ShortUUID.encode(UUID.uuid4())

    request = Req.new(
      base_url: config.base_url,
      auth: {:basic, "#{config.access_key_id}:#{config.secret_access_key}"},
      headers: [{"content-type", "application/octet-stream"}]
    )

    response = Req.put!(request, url: "/containers/#{config.container}/import/datasources/#{d_config.datasource}/files?action=uploadPart&key=#{state.file_key}&block_id=#{block_id}", body: data)

    case response do
      %{status: 200} ->
        {:ok, {destination, %{state | parts: [response.body.block_id | state.parts]}}}
      %{status: status} ->
        {:error, status}
    end
  end

  def commit(%Destinations.Destination{} = destination, _filename, state, _opts \\ []) do
    %DeepLynxConfig{} = d_config = destination.deeplynx_config
    config = %DeepLynxConfig{
      base_url: d_config.base_url,
      access_key_id: d_config.access_key_id,
      secret_access_key: d_config.secret_access_key,
      container: d_config.container,
      datasource: d_config.datasource
    }

    request = Req.new(
      base_url: config.base_url,
      auth: {:basic, "#{config.access_key_id}:#{config.secret_access_key}"},
      headers: [{"content-type", "application/octet-stream"}]
    )

    response = Req.put!(request, url: "/containers/#{config.container}/import/datasources/#{d_config.datasource}/files?action=commitParts&key=#{state.file_key}", body: state.parts)

    case response do
      %{status: 200} ->
        # path field is the file id. The destination is the container and datasource
        {:ok, {destination, response.body.id}}
      %{status: status} ->
        {:error, status}
    end
  end
end
