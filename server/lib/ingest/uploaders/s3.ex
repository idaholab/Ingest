defmodule Ingest.Uploaders.S3 do
  @moduledoc """
  Used for uploading to S3 storage.
  """
  alias Ingest.Destinations.S3Config
  alias Ingest.Destinations.LakeFSConfig
  alias Ingest.Destinations.Destination

  def init(%Destination{} = destination, filename, state) do
    # first we check if the object by filename and path exist in the bucket already
    # if it does, then we need to change the name and appened a - COPY (date) to the end of it
    filename =
      with s3_op <- ExAws.S3.head_object(destination.s3_config.bucket, filename),
           s3_config <- ExAws.Config.new(:ex_aws, build_config(destination.s3_config)),
           {:ok, %{body: body}} <- ExAws.request(s3_op, s3_config) do
        "#{filename} - COPY #{DateTime.now!("UTC") |> DateTime.to_naive()}"
      else
        # assumption is that the error is a 404 not found, so we can keep the filename
        _ -> filename
      end

    with s3_op <- ExAws.S3.initiate_multipart_upload(destination.s3_config.bucket, filename),
         s3_config <- ExAws.Config.new(:ex_aws, build_config(destination.s3_config)),
         {:ok, %{body: %{upload_id: upload_id}}} <- ExAws.request(s3_op, s3_config) do
      {:ok,
       {destination,
        state
        |> Map.put(:chunk, 1)
        |> Map.put(:config, s3_config)
        |> Map.put(:op, s3_op)
        |> Map.put(:upload_id, upload_id)
        |> Map.put(:parts, [])}}
    else
      err -> {:error, err}
    end
  end

  def upload_full_object(%Destination{} = destination, filename, data) do
    with s3_op <- ExAws.S3.put_object(destination.s3_config.bucket, filename, data),
         s3_config <- ExAws.Config.new(:ex_aws, build_config(destination.s3_config)),
         {:ok, %{body: %{upload_id: upload_id}}} <- ExAws.request(s3_op, s3_config) do
      {:ok, upload_id}
    else
      err -> {:error, err}
    end
  end

  def upload_chunk(%Destination{} = destination, _filename, state, data) do
    part = ExAws.S3.Upload.upload_chunk({data, state.chunk}, state.op, state.config)

    case part do
      {:error, err} -> {:error, err}
      _ -> {:ok, {destination, %{state | chunk: state.chunk + 1, parts: [part | state.parts]}}}
    end
  end

  def commit(%Destination{} = destination, _filename, state) do
    result = ExAws.S3.Upload.complete(state.parts, state.op, state.config)

    case result do
      {:ok, %{body: %{key: key}}} ->
        {:ok, {destination, key}}

      _ ->
        {:error, result}
    end
  end

  defp build_config(%S3Config{} = s3_config) do
    ExAws.Config.new(:s3, %{
      ex_aws: [
        access_key_id: s3_config.access_key_id,
        secret_access_key: s3_config.secret_access_key,
        region: Map.get(s3_config, s3_config.region, "us-east-1"),
        s3: [
          host: Map.get(s3_config, s3_config.base_url, nil),
          scheme:
            if Map.get(s3_config, s3_config.ssl, true) do
              "https://"
            else
              "http://"
            end
        ]
      ]
    })
  end

  defp build_config(%LakeFSConfig{} = config) do
    ExAws.Config.new(:s3, %{
      ex_aws: [
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key,
        region: Map.get(config, config.region, "us-east-1"),
        s3: [
          host: Map.get(config, config.base_url, nil),
          scheme:
            if Map.get(config, config.ssl, true) do
              "https://"
            else
              "http://"
            end
        ]
      ]
    })
  end
end
