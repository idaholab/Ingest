defmodule Ingest.LakeFS do
  @moduledoc """
  All functions pertaining to communicating with LakeFS.
  """

  alias Req
  require Logger

  @default_lakefs_url "http://localhost:8000"

  # Fetches LakeFS configuration once and caches the values
  defp lakefs_config do
    %{
      url: url,
      access_key: access_key,
      secret_access_key: secret_access_key
    } = Application.fetch_env!(:ingest, :lakefs)

    {url || @default_lakefs_url, access_key, secret_access_key}
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

  # Download a file from LakeFS
  def download_file(repo, ref, path) do
    lakefs_request(:get, "repositories/#{repo}/refs/#{ref}/objects", [path: path])
  end

  # Download metadata directly from the object storage
  def download_metadata(repo, ref, path) do
    lakefs_request(:get, "repositories/#{repo}/refs/#{ref}/objects/stat", [path: path])
  end

  # Get a presigned URL for downloading files
  def presigned_download_url(repo, ref, path) do
    lakefs_request(:get, "repositories/#{repo}/refs/#{ref}/objects",
      [path: path, presign: true],
      [redirect: false]
    )
  end

  # Check if the repository exists or create it if it doesn't
  def check_or_create_repo(client, repo_name) do
    # Build the full URL properly
    url = lakefs_url("repositories/#{repo_name}")

    Logger.debug("Checking if repository '#{repo_name}' exists at URL: #{url}")

    response = Req.get(url, auth: client.auth)

    case response do
      {:ok, %{status: 200}} ->
        Logger.info("Repository '#{repo_name}' exists.")
        {:ok, "Repository exists"}

      {:ok, %{status: 404}} ->
        Logger.info("Repository '#{repo_name}' does not exist. Attempting to create it.")
        create_repo(client, repo_name)

      {:error, error} ->
        Logger.error("Error checking if repository exists. Error: #{inspect(error)}")
        {:error, error}
    end
  end

  # Create a repository in LakeFS
  defp create_repo(client, repo_name) do
    url = lakefs_url("repositories")

    Logger.debug("Starting repository creation process for '#{repo_name}' at URL: #{url}")

    response = Req.post(
      url,
      auth: client.auth,
      json: %{
        name: repo_name,
        storage_namespace: "#{client.endpoint}/#{repo_name}",
        default_branch: "main",
        sample_data: true,
        read_only: false
      }
    )

    Logger.debug("LakeFS create repository request payload: %{
      url: #{url},
      repository_name: #{repo_name},
      storage_namespace: #{client.endpoint}/#{repo_name}
    }")

    case response do
      {:ok, %{status: 201, body: body}} ->
        Logger.info("Repository '#{repo_name}' created successfully. Response: #{inspect(body)}")
        {:ok, "Repository created successfully"}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to create repository '#{repo_name}'. Unexpected status: #{status}. Response: #{inspect(body)}")
        {:error, {:unexpected_status, status, body}}

      {:error, error} ->
        Logger.error("Error occurred while creating repository '#{repo_name}': #{inspect(error)}")
        {:error, error}
    end
  end

  # Helper function to construct the URL for LakeFS API endpoints
  defp lakefs_url(path, repo \\ nil, ref \\ nil) do
    {base_url, _, _} = lakefs_config()
    base_path = "#{base_url}/api/v1"

    url =
      cond do
        repo && ref -> "#{base_path}/repositories/#{repo}/refs/#{ref}/#{path}"
        repo -> "#{base_path}/repositories/#{repo}/#{path}"
        true -> "#{base_path}/#{path}"
      end

    Logger.debug("Constructed LakeFS URL: #{url}")
    url
  end

  # Perform a diff merge with callbacks for added, changed, and removed files
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
