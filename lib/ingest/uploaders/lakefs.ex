defmodule Ingest.Uploaders.Lakefs do
  @moduledoc """
  Used for uploading to LakeFS repositories. Typically a request will open a branch
  specifically for the user doing the upload, can be traced all the way back.
  """
  alias Ingest.Accounts.User
  alias Ingest.Requests.Request
  alias Ingest.Destinations.LakeFSConfig
  alias Ingest.Destinations.Destination
  require Logger

  def init!(%Destination{} = destination, filename, state, opts \\ []) do
    original_filename = Keyword.get(opts, :original_filename, nil)

    # we need validate/create if not exists a branch for the request & user email
    branch_name = upsert_branch(destination, state.request, state.user)

    repository =
      if destination.additional_config do
        destination.additional_config["repository_name"]
      else
        destination.lakefs_config.repository
      end

    Logger.info(
      "THIS IS TESTING BUILD CONFIG IN INIT #{inspect(build_config(destination.lakefs_config))}"
    )

    # first we check if the object by filename and path exist in the bucket already
    # if it does, then we need to change the name and appened a - COPY (date) to the end of it
    filename =
      with s3_op <-
             ExAws.S3.head_object(
               "#{repository}/#{branch_name}",
               filename
             ),
           s3_config <- build_config(destination.lakefs_config),
           {:ok, %{headers: _headers}} <- ExAws.request(s3_op, s3_config) do
        "#{filename} - COPY #{DateTime.now!("UTC") |> DateTime.to_naive()}"
      else
        # assumption is that the error is a 404 not found, so we can keep the filename
        _ -> filename
      end

    filename =
      if original_filename do
        "#{original_filename} Supporting Data/ #{filename}"
      else
        filename
      end

    with s3_op <-
           ExAws.S3.initiate_multipart_upload(
             "#{repository}/#{branch_name}",
             filename
           ),
         s3_config <- build_config(destination.lakefs_config),
         {:ok, %{body: %{upload_id: upload_id}}} <- ExAws.request(s3_op, s3_config) do
      {:ok,
       {destination,
        state
        |> Map.put(:filename, filename)
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
    branch_name = upsert_branch(destination, request, user)

    repository =
      if destination.additional_config do
        destination.additional_config["repository_name"]
      else
        destination.lakefs_config.repository
      end

    s3_op = ExAws.S3.put_object("#{repository}/#{branch_name}", filename, data)
    s3_config = build_config(destination.lakefs_config)

    case ExAws.request(s3_op, s3_config) do
      {:ok, %{status_code: 200}} ->
        {:ok, :uploaded}

      {:ok, other} ->
        {:error, {:unexpected_success_response, other}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_metadata(
        %Destination{} = destination,
        %Request{} = request,
        %User{} = user,
        filename,
        data
      ) do
    # we need validate/create if not exists a branch for the request & user email
    branch_name = upsert_branch(destination, request, user)

    repository =
      if destination.additional_config do
        destination.additional_config["repository_name"]
      else
        destination.lakefs_config.repository
      end

    Logger.info(
      "THIS IS TESTING BUILD CONFIG IN METADATA #{inspect(build_config(destination.lakefs_config))}"
    )

    with s3_op <-
           ExAws.S3.put_object_copy(
             "#{repository}/#{branch_name}",
             filename,
             "#{repository}/#{branch_name}",
             filename,
             [{:metadata_directive, "REPLACE"}, {:meta, data}]
           ),
         s3_config <- build_config(destination.lakefs_config),
         {:ok, %{body: %{upload_id: upload_id}}} <- ExAws.request(s3_op, s3_config) do
      {:ok, upload_id}
    else
      err -> {:error, err}
    end
  end

  def upload_chunk(%Destination{} = destination, _filename, state, data, _opts \\ []) do
    part = ExAws.S3.Upload.upload_chunk({data, state.chunk}, state.op, state.config)

    case part do
      {:error, err} -> {:error, err}
      _ -> {:ok, {destination, %{state | chunk: state.chunk + 1, parts: [part | state.parts]}}}
    end
  end

  def commit(%Destination{} = destination, _filename, state, _opts \\ []) do
    result = ExAws.S3.Upload.complete(state.parts, state.op, state.config)

    case result do
      {:ok, %{body: %{key: _key}}} ->
        {:ok, {destination, state.filename}}

      _ ->
        {:error, result}
    end
  end

  defp build_config(%LakeFSConfig{} = config) do
    ExAws.Config.new(:s3,
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
    )
  end

  defp upsert_branch(%Destination{} = destination, %Request{} = request, %User{} = user) do
    branch_name = Regex.replace(~r/\W+/, "#{request.name}-by-#{user.name}", "-")
    config = destination.lakefs_config

    repository =
      if destination.additional_config do
        destination.additional_config["repository_name"]
      else
        destination.lakefs_config.repository
      end

    with client <-
           Ingest.LakeFS.new!(
             %URI{
               host: config.base_url,
               scheme: if(config.ssl, do: "https", else: "http"),
               port: config.port
             },
             access_key: config.access_key_id,
             secret_access_key: config.secret_access_key
           ),
         {:ok, branches} <- Ingest.LakeFS.list_branches(client, repository) do
      branch =
        Enum.find(branches, fn b -> b["id"] == branch_name end)

      if !branch do
        {:ok, _res} =
          Ingest.LakeFS.new!(
            %URI{
              host: config.base_url,
              scheme: if(config.ssl, do: "https", else: "http"),
              port: config.port
            },
            access_key: config.access_key_id,
            secret_access_key: config.secret_access_key,
            port: config.port
          )
          |> Ingest.LakeFS.create_branch(
            repository,
            branch_name
          )
      end

      branch_name
    else
      {:error, _err} -> nil
    end
  end
end
