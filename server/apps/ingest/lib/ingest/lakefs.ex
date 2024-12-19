defmodule Ingest.LakeFS do
  @moduledoc """
  All functions pertaining to communicating with LakeFS.
  """

  alias Req

  @default_lakefs_url "http://localhost:8000"

  # Fetches LakeFS configuration once and caches the values.
  defp lakefs_config do
    %{
      url: url,
      access_key: access_key,
      secret_access_key: secret_access_key
    } = Application.fetch_env!(:ingest, :lakefs)

    url_value = if url, do: url, else: @default_lakefs_url

    {url_value, access_key, secret_access_key}
  end

  # Wrapper for sending LakeFS requests to avoid repeated boilerplate
  defp lakefs_request(method, path, params \\ [], opts \\ []) do
    {_, access_key, secret_access_key} = lakefs_config()
    url = lakefs_url(path)

    Req.request(
      method: method,
      url: url,
      auth: {:basic, "#{access_key}:#{secret_access_key}"},
      params: params,
      opts: opts
    )
  end

  @doc "Downloads a file from LakeFS."
  def download_file(repo, ref, path) do
    lakefs_request(:get, "repositories/#{repo}/refs/#{ref}/objects", [path: path])
  end

  @doc "Downloads metadata for an object from LakeFS."
  def download_metadata(repo, ref, path) do
    lakefs_request(:get, "repositories/#{repo}/refs/#{ref}/objects/stat", [path: path])
  end

  @doc "Generates a presigned URL for downloading an object from LakeFS."
  def presigned_download_url(repo, ref, path) do
    lakefs_request(:get, "repositories/#{repo}/refs/#{ref}/objects",
      [path: path, presign: true],
      [redirect: false]
    )
  end

  @doc "Checks if a repository exists, creates it if not."
  def check_or_create_repo(client, repo_name) do
    if repo_name in [nil, ""] do
      {:error, "Repository name cannot be empty"}
    else
      url = lakefs_url("repositories/#{repo_name}")

      with {:ok, %{status: 200}} <- Req.get(url, auth: client.auth) do
        {:ok, "Repository exists"}
      else
        {:ok, %{status: 404}} ->
          create_repo(client, repo_name)

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:unexpected_status, status, body}}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  @doc "Creates a new repository in LakeFS."
  def create_repo(client, repo_name) do
    storage_namespace =
      cond do
        to_string(client.endpoint) =~ "localhost" or to_string(client.endpoint) =~ "127.0.0.1" ->
          "local://#{repo_name}"
        to_string(client.endpoint) =~ ~r/^https?:\/\// ->
          "#{client.endpoint}/#{repo_name}"
        true ->
          "s3://#{client.endpoint}/#{repo_name}"
      end

    url = lakefs_url("repositories")

    payload = %{
      name: repo_name,
      storage_namespace: storage_namespace,
      default_branch: "main",
      read_only: false
    }

    case Req.post(url, auth: client.auth, json: payload) do
      {:ok, %{status: 201, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, {:unexpected_status, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Constructs the LakeFS API URL.
  defp lakefs_url(path) do
    base_url = "http://localhost:8000/api/v1"
    "#{base_url}/#{path}"
  end

  # Performs a diff merge with callbacks for file changes.
  def diff_merge(
        %{
          "event_type" => "pre-merge",
          "source_ref" => source_ref,
          "branch_id" => "main",
          "repository_id" => repo
        } = _event,
        on_delete,
        on_update,
        on_create
      ) do
    url = lakefs_url("repositories/#{repo}/refs/main/diff/#{source_ref}")

    with {:ok, %{status: 200, body: %{"results" => results}}} <- lakefs_request(:get, url) do
      {statuses, messages} =
        Enum.reduce(results, {[], []}, fn result, {status_acc, msg_acc} ->
          {status, message} =
            case result["type"] do
              "added" -> on_create.(repo, source_ref, result)
              "changed" -> on_update.(repo, source_ref, result)
              "removed" -> on_delete.(repo, source_ref, result)
            end

          {[status | status_acc], [message | msg_acc]}
        end)

      if :error in statuses do
        {:error, messages}
      else
        {:ok, messages}
      end
    else
      error ->
        {:error, error}
    end
  end
end
