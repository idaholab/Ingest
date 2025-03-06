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

    container = Keyword.get(opts, :container, nil)
    datasource = Keyword.get(opts, :datasource, nil)
    file_key = ShortUUID.encode(UUID.uuid4())

    request =
      Req.new(
        base_url: d_config.base_url,
        auth: {:basic, "#{d_config.api_key}:#{d_config.api_secret}"},
        headers: [
          {"content-type", "application/json"},
          {"x-api-key", "#{d_config.api_key}"},
          {"x-api-secret", "#{d_config.api_secret}"}
        ]
      )

    bearer_token_res =
      Req.get!(request,
        url: "/oauth/token"
      )

    # todo: return if bearer_token_res is an error, let user know key:secret pair is out of date

    # todo: if datasource is nil, then hit the endpoint to create a new datasource

    {:ok,
     {destination,
      state
      |> Map.put(:base_url, d_config.base_url)
      |> Map.put(:container, container)
      |> Map.put(:datasource, datasource)
      |> Map.put(:bearer_token, bearer_token_res.body)
      |> Map.put(:file_key, elem(file_key, 1))
      |> Map.put(:filename, filename)
      |> Map.put(:parts, [])}}
  end

  def update_metadata(%Destinations.Destination{} = destination, path, metadata) do
    %DeepLynxConfig{} = d_config = destination.deeplynx_config

    config = %DeepLynxConfig{
      base_url: d_config.base_url,
      api_key: d_config.api_key,
      api_secret: d_config.api_secret,
      container: d_config.container,
      datasource: d_config.datasource
    }

    bearer_token_request =
      Req.new(
        base_url: d_config.base_url,
        auth: {:basic, "#{d_config.api_key}:#{d_config.api_secret}"},
        headers: [
          {"content-type", "application/json"},
          {"x-api-key", "#{d_config.api_key}"},
          {"x-api-secret", "#{d_config.api_secret}"}
        ]
      )

    bearer_token_res =
      Req.get!(bearer_token_request,
        url: "/oauth/token"
      )

    # todo: return if bearer_token_res is an error, let user know key:secret pair is out of date

    metadata_request =
      Req.new(
        base_url: config.base_url,
        auth: {:bearer, bearer_token_res.body},
        headers: [{"content-type", "application/octet-stream"}]
      )

    response =
      Req.post!(metadata_request,
        url:
          "container/#{config.container}/import/datasources/#{config.datasource}/#{path}/metadata",
        body: metadata
      )

    case response do
      %{status: 200} ->
        {:ok, response.body}

      %{status: status} ->
        {:error, status}
    end
  end

  def upload_full_object(%Destinations.Destination{} = destination, path, data) do
    %DeepLynxConfig{} = d_config = destination.deeplynx_config

    config = %DeepLynxConfig{
      base_url: d_config.base_url,
      api_key: d_config.api_key,
      api_secret: d_config.api_secret,
      container: d_config.container,
      datasource: d_config.datasource
    }

    bearer_token_request =
      Req.new(
        base_url: d_config.base_url,
        auth: {:basic, "#{d_config.api_key}:#{d_config.api_secret}"},
        headers: [
          {"content-type", "application/json"},
          {"x-api-key", "#{d_config.api_key}"},
          {"x-api-secret", "#{d_config.api_secret}"}
        ]
      )

    bearer_token_res =
      Req.get!(bearer_token_request,
        url: "/oauth/token"
      )

    # todo: return if bearer_token_res is an error, let user know key:secret pair is out of date

    request =
      Req.new(
        base_url: config.base_url,
        auth: {:bearer, bearer_token_res.body},
        headers: [{"content-type", "application/octet-stream"}]
      )

    response =
      Req.post!(request,
        url: "/containers/#{config.container}/import/datasources/#{config.datasource}/files",
        body: data
      )

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
      api_key: d_config.api_key,
      api_secret: d_config.api_secret,
      container: d_config.container,
      datasource: d_config.datasource
    }

    block_id = ShortUUID.encode(UUID.uuid4())

    request =
      Req.new(
        base_url: config.base_url,
        auth: {:bearer, state.bearer_token},
        headers: [{"content-type", "application/octet-stream"}]
      )

    # not empty when it's sent
    dbg(data)

    response =
      Req.put!(request,
        url:
          "/containers/#{config.container}/import/datasources/#{d_config.datasource}/files?action=uploadPart&key=#{state.file_key}&block_id=#{elem(block_id, 1)}",
        body: data
      )

    case response do
      %{status: 200} ->
        {:ok, {destination, %{state | parts: [elem(block_id, 1) | state.parts]}}}

      %{status: status} ->
        {:error, status}
    end
  end

  def commit(%Destinations.Destination{} = destination, _filename, state, _opts \\ []) do
    %DeepLynxConfig{} = d_config = destination.deeplynx_config

    config = %DeepLynxConfig{
      base_url: d_config.base_url,
      api_key: d_config.api_key,
      api_secret: d_config.api_secret,
      container: d_config.container,
      datasource: d_config.datasource
    }

    request =
      Req.new(
        base_url: config.base_url,
        auth: {:bearer, state.bearer_token},
        headers: [{"content-type", "application/octet-stream"}]
      )

    response =
      Req.put!(request,
        url:
          "/containers/#{config.container}/import/datasources/#{d_config.datasource}/files?action=commitParts&key=#{state.file_key}",
        body: state.parts
      )

    case response do
      %{status: 200} ->
        # path field is the file id. The destination is the container and datasource
        {:ok, {destination, response.body.id}}

      %{status: status} ->
        {:error, status}
    end
  end
end
