defmodule Ingest.LakeFS do
  @moduledoc """
  All functions pertaining to communicating with LakeFS.
  """

  @enforce_keys [:endpoint]
  defstruct [:endpoint, :access_key, :secret_access_key, :base_req]

  @doc """
  Contains options for setting the access and secret access key
  """
  def new(endpoint, opts \\ []) do
    case URI.new(endpoint) do
      {:ok, uri} ->
        {:ok,
         %__MODULE__{
           endpoint: uri,
           access_key: Keyword.get(opts, :access_key),
           secret_access_key: Keyword.get(opts, :secret_access_key),
           base_req:
             Req.new(
               base_url:
                 "#{endpoint}#{if Keyword.get(opts, :port) do
                   ":#{Keyword.get(opts, :port)}"
                 end}",
               auth:
                 {:basic,
                  "#{Keyword.get(opts, :access_key)}:#{Keyword.get(opts, :secret_access_key)}"}
             )
         }}

      _ ->
        {:error, "unable to parse endpoint"}
    end
  end

  def new!(endpoint, opts \\ []) do
    %__MODULE__{
      endpoint: URI.new!(endpoint),
      access_key: Keyword.get(opts, :access_key),
      secret_access_key: Keyword.get(opts, :secret_access_key),
      base_req:
        Req.new(
          base_url:
            "#{endpoint}#{if Keyword.get(opts, :port) do
              ":#{Keyword.get(opts, :port)}"
            end}",
          auth:
            {:basic, "#{Keyword.get(opts, :access_key)}:#{Keyword.get(opts, :secret_access_key)}"}
        )
    }
  end

  @doc """
  Lists all repositories
  """
  def list_repos(%__MODULE__{} = client) do
    case Req.get(client.base_req, url: "/api/v1/repositories") do
      {:ok, %{body: %{"results" => results}}} -> {:ok, results}
      {:error, res} -> {:error, res}
    end
  end

  @doc """
  Lists all current branches for a repository
  """
  def list_branches(%__MODULE__{} = client, repository) do
    case Req.get(client.base_req, url: "/api/v1/repositories/#{URI.encode(repository)}/branches") do
      {:ok, %{body: %{"results" => results}}} -> {:ok, results}
      {:error, res} -> {:error, res}
    end
  end

  @doc """
  Creates a new branch for the repository. Will error if the branch exists
  """
  def create_branch(%__MODULE__{} = client, repository, name, source \\ "main") do
    case Req.post(client.base_req,
           url: "/api/v1/repositories/#{URI.encode(repository)}/branches",
           json: %{
             name: name,
             source: source
           }
         ) do
      {:ok, %{status: 201}} -> {:ok, nil}
      {:error, res} -> {:error, res}
    end
  end

  # note: do not use this function for massive files as it does not treat the response
  # as a stream - if you need a stream, you'll need to write it in as this is typically
  # used for getting the m.json files and those are going to be held in memory anyways
  @deprecated "Use get_file instead"
  def download_file(repo, ref, path) do
    config = Application.get_env(:ingest, :lakefs)
    url = config[:url]
    key = config[:access_key]
    secret = config[:secret_access_key]

    case Req.get!("#{url}/api/v1/repositories/#{repo}/refs/#{ref}/objects",
           params: [path: path],
           auth: {:basic, "#{key}:#{secret}"}
         ) do
      %{status: 200, body: body} -> {:ok, body}
      err -> {:error, err}
    end
  end

  @deprecated "Use presigned_url instead"
  def presigned_download_url(url, repo, ref, path) do
    config = Application.get_env(:ingest, :lakefs)
    key = config[:access_key]
    secret = config[:secret_access_key]

    resp =
      Req.get!("#{url}/api/v1/repositories/#{repo}/refs/#{ref}/objects",
        params: [path: path, presign: true],
        auth: {:basic, "#{key}:#{secret}"},
        redirect: false
      )

    # we return the raw response struct here for ease of use
    {:ok, resp}
  end

  # this function pulls the metadata out of the object storage itself, as we are no longer storing
  # it as .m.json files but intead on the objects themselves
  @deprecated "Use get_metadata instead"
  def download_metadata(repo, ref, path) do
    config = Application.get_env(:ingest, :lakefs)
    url = config[:url]
    key = config[:access_key]
    secret = config[:secret_access_key]

    with %{status: 200, body: body} <-
           Req.get!("#{url}/api/v1/repositories/#{repo}/refs/#{ref}/objects/stat",
             params: [path: path],
             auth: {:basic, "#{key}:#{secret}"}
           ) do
      {:ok, body}
    else
      err -> {:error, err}
    end
  end

  # the diff merge function takes 3 functions, to be executed depending on whether or not
  # a file in the merge has been changed, removed, or created
  @deprecated "Use handle_diff_merge instead"
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
    config = Application.get_env(:ingest, :lakefs)
    url = config[:url]
    key = config[:access_key]
    secret = config[:secret_access_key]

    with %{status: 200, body: %{"results" => results} = _body} <-
           Req.get!("#{url}/api/v1/repositories/#{repo}/refs/main/diff/#{source_ref}",
             auth: {:basic, "#{key}:#{secret}"}
           ) do
      # Example of a result:
      # {"path" => "data01.csv", "path_type" => "object", "size_bytes" => 11, "type" => "changed"}
      {statuses, messages} =
        results
        |> Enum.map(fn result ->
          case result["type"] do
            "added" -> on_create.(repo, source_ref, result)
            "changed" -> on_update.(repo, source_ref, result)
            "removed" -> on_delete.(repo, source_ref, result)
          end
        end)
        |> Enum.unzip()

      if statuses |> Enum.member?(:error) do
        {:error, messages}
      else
        {:ok, messages}
      end
    else
      err -> {:error, err}
    end
  end
end
