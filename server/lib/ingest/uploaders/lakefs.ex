defmodule Ingest.Uploaders.Lakefs do
  @moduledoc """
  Used for uploading to LakeFS repositories. Typically a request will open a branch
  specifically for the user doing the upload, can be traced all the way back.
  """
  alias Ingest.Accounts.User
  alias Ingest.Requests.Request
  alias Ingest.Destinations.S3Config
  alias Ingest.Destinations.LakeFSConfig
  alias Ingest.Destinations.Destination

  def init(%Destination{} = destination, filename, state) do
    # we need validate/create if not exists a branch for the request & user email
    branch_name = upsert_branch(destination.lakefs_config, state.request, state.user)

    with s3_op <-
           ExAws.S3.initiate_multipart_upload(
             "#{destination.lakefs_config.repository}/#{branch_name}",
             filename
           ),
         s3_config <- ExAws.Config.new(:s3, build_config(destination.lakefs_config)),
         {:ok, %{body: %{upload_id: upload_id}}} <- ExAws.request(s3_op, s3_config) do
      {:ok,
       {destination,
        state
        |> Map.put(:chunk, 1)
        |> Map.put(:config, s3_config)
        |> Map.put(:op, s3_op |> Map.put(:upload_id, upload_id) |> Map.put(:opts, []))
        |> Map.put(:upload_id, upload_id)
        |> Map.put(:parts, [])}}
    else
      err -> {:error, err}
    end
  end

  def upload_full_object(
        %Destination{} = destination,
        %Request{} = request,
        %User{} = user,
        filename,
        data
      ) do
    # we need validate/create if not exists a branch for the request & user email
    branch_name = upsert_branch(destination.lakefs_config, request, user)

    with s3_op <-
           ExAws.S3.put_object(
             "#{destination.lakefs_config.repository}/#{branch_name}",
             filename,
             data
           ),
         s3_config <- ExAws.Config.new(:s3, build_config(destination.lakefs_config)),
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

  def commit(%Destination{} = _destination, _filename, state) do
    result = ExAws.S3.Upload.complete(state.parts, state.op, state.config)

    case result do
      {:ok, %{body: %{location: location}}} ->
        {:ok, location}

      _ ->
        {:error, result}
    end
  end

  defp build_config(%LakeFSConfig{} = config) do
    ExAws.Config.new(:s3, %{
      host: Map.get(config, :base_url, nil),
      scheme:
        if Map.get(config, :ssl, true) do
          "https://"
        else
          "http://"
        end,
      port: config.port,
      access_key_id: config.access_key_id,
      secret_access_key: config.secret_access_key,
      ex_aws: [
        access_key_id: config.access_key_id,
        secret_access_key: config.secret_access_key,
        region: Map.get(config, config.region, "us-east-1")
      ]
    })
  end

  defp upsert_branch(%LakeFSConfig{} = config, %Request{} = request, %User{} = user) do
    branch_name = Regex.replace(~r/\W+/, "#{request.name}-by-#{user.name}", "-")

    base_url =
      if config.ssl do
        "https://#{config.base_url}"
      else
        "http://#{config.base_url}"
      end

    with client <-
           Ingest.Destinations.Lakefs.new_client(
             base_url,
             {config.access_key_id, config.secret_access_key},
             port: config.port
           ),
         {:ok, branches} <- Ingest.Destinations.Lakefs.list_branches(client, config.repository) do
      branch =
        Enum.find(branches, fn b -> b["id"] == branch_name end)

      if !branch do
        {:ok, _res} =
          Ingest.Destinations.Lakefs.new_client(
            base_url,
            {config.access_key_id, config.secret_access_key},
            port: config.port
          )
          |> Ingest.Destinations.Lakefs.create_branch(
            config.repository,
            branch_name
          )
      end

      branch_name
    else
      {:error, err} -> nil
    end
  end
end
