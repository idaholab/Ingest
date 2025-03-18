defmodule Ingest.LakeFS do
  @moduledoc """
  All functions pertaining to communicating with LakeFS.
  """

  @enforce_keys [:endpoint]
  defstruct [:endpoint, :access_key, :secret_access_key, :base_req, :storage_namespace]

  @doc """
  Contains options for setting the access and secret access key
  """
  def new(%URI{} = endpoint, opts \\ []) do
    {:ok,
     %__MODULE__{
       endpoint: endpoint,
       access_key: Keyword.get(opts, :access_key),
       secret_access_key: Keyword.get(opts, :secret_access_key),
       storage_namespace: Keyword.get(opts, :storage_namespace),
       base_req:
         Req.new(
           base_url: URI.to_string(endpoint),
           auth:
             {:basic,
              "#{Keyword.get(opts, :access_key)}:#{Keyword.get(opts, :secret_access_key)}"}
         )
     }}
  end

  def new!(%URI{} = endpoint, opts \\ []) do
    %__MODULE__{
      endpoint: endpoint,
      access_key: Keyword.get(opts, :access_key),
      secret_access_key: Keyword.get(opts, :secret_access_key),
      storage_namespace: Keyword.get(opts, :storage_namespace),
      base_req:
        Req.new(
          base_url: URI.to_string(endpoint),
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
  Lists all users
  """
  def list_users(%__MODULE__{} = client) do
    # we shouldn't need to return more than 10k users at any point
    case Req.get(client.base_req, url: "/api/v1/auth/users", params: [amount: 10000]) do
      {:ok, %{body: %{"results" => results}}} -> {:ok, results}
      {:error, res} -> {:error, res}
    end
  end

  @doc """
  Get single repository
  """
  def get_repo(%__MODULE__{} = client, repo) do
    case Req.get(client.base_req, url: "/api/v1/repositories/#{URI.encode(repo)}") do
      {:ok, %{body: repo, status: 200}} -> {:ok, repo}
      {:error, res} -> {:error, res}
      _ -> {:error, :not_found}
    end
  end

  def create_repo(%__MODULE__{} = client, repo, opts \\ []) do
    case Req.post(client.base_req,
           url: "/api/v1/repositories",
           json: %{
             name: repo,
             storage_namespace: Keyword.get(opts, :storage_namespace, client.storage_namespace),
             default_branch: Keyword.get(opts, :default_branch, "main"),
             read_only: Keyword.get(opts, :read_only, false)
           }
         ) do
      {:ok, %{body: repo, status: 201}} -> {:ok, repo}
      {:ok, %{body: %{"message" => message}, status: 409}} -> {:error, message}
      {:error, res} -> {:error, res}
      message -> {:error, message}
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

  def create_policy(%__MODULE__{} = client, policy) do
    case Req.post(client.base_req,
           url: "/api/v1/auth/policies",
           body: policy,
           headers: [content_type: "application/json"]
         ) do
      {:ok, %{body: repo, status: 201}} -> {:ok, repo}
      {:ok, %{body: %{"message" => message}, status: 409}} -> {:error, message}
      {:error, res} -> {:error, res}
      message -> {:error, message}
    end
  end

  def create_group(%__MODULE__{} = client, group) do
    case Req.post(client.base_req,
           url: "/api/v1/auth/groups",
           json: %{id: "#{group}"}
         ) do
      {:ok, %{body: repo, status: 201}} -> {:ok, repo}
      {:ok, %{body: %{"message" => message}, status: 409}} -> {:error, message}
      {:error, res} -> {:error, res}
      message -> {:error, message}
    end
  end

  def create_user(%__MODULE__{} = client, user, opts \\ []) do
    case Req.post(client.base_req,
           url: "/api/v1/auth/users",
           json: %{
             id: "#{user}",
             email: Keyword.get(opts, :email),
             invite_user: Keyword.get(opts, :invite_user, true)
           }
         ) do
      {:ok, %{body: user, status: 201}} -> {:ok, user}
      # 409 indicates a user with that ID exists, so let's just return a shell with the ID
      {:ok, %{body: %{"message" => message}, status: 409}} -> {:ok, %{"id" => user}}
      {:error, res} -> {:error, res}
      message -> {:error, message}
    end
  end

  def attach_user_group(%__MODULE__{} = client, group, user) do
    case Req.put(client.base_req,
           url: "/api/v1/auth/groups/#{group}/members/#{user}"
         ) do
      {:ok, %{status: 201}} -> :ok
      {:ok, %{body: %{"message" => message}, status: 409}} -> {:error, message}
      {:error, res} -> {:error, res}
      message -> {:error, message}
    end
  end

  def attach_group_policy(%__MODULE__{} = client, group, policy) do
    case Req.put(client.base_req,
           url: "/api/v1/auth/groups/#{group}/policies/#{policy}"
         ) do
      {:ok, %{status: 201}} -> :ok
      {:ok, %{body: %{"message" => message}, status: 409}} -> {:error, message}
      {:error, res} -> {:error, res}
      message -> {:error, message}
    end
  end

  def put_object(%__MODULE__{} = client, repo, path, object, opts \\ []) do
    case Req.post(client.base_req,
           url:
             "/api/v1/repositories/#{repo}/branches/#{Keyword.get(opts, :branch, "main")}/objects?path=#{URI.encode(path)}",
           body: object,
           headers: [content_type: "application/octet-stream"]
         ) do
      {:ok, %{status: 201}} -> :ok
      {:ok, %{body: %{"message" => message}, status: 409}} -> {:error, message}
      {:error, res} -> {:error, res}
      message -> {:error, message}
    end
  end

  def protect_branch(%__MODULE__{} = client, repo, branch_pattern) do
    case Req.put(client.base_req,
           url: "/api/v1/repositories/#{repo}/settings/branch_protection",
           json: [%{pattern: branch_pattern}]
         ) do
      {:ok, %{status: 204}} -> :ok
      {:error, res} -> {:error, res}
      message -> {:error, message}
    end
  end

  def commit_changes(%__MODULE__{} = client, repo, opts \\ []) do
    case Req.post(client.base_req,
           url:
             "api/v1/repositories/#{repo}/branches/#{Keyword.get(opts, :branch, "main")}/commits",
           json: %{message: Keyword.get(opts, :message)}
         ) do
      {:ok, %{body: commit, status: 201}} -> {:ok, commit}
      {:ok, %{body: %{"message" => message}, status: 409}} -> {:error, message}
      {:error, res} -> {:error, res}
      message -> {:error, message}
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

  def admin_policy(repo_name) do
    ~s"""
      {
        "id": "#{repo_name}-admin-policy",
        "statement": [
            {
                "action": [
                    "fs:ReadRepository",
                    "fs:ReadCommit",
                    "fs:ListBranches",
                    "fs:ListTags",
                    "fs:ListObjects",
                    "pr:ReadPullRequest",
                    "pr:WritePullRequest",
                    "pr:ListPullRequests"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}"
            },
            {
                "action": [
                    "fs:RevertBranch",
                    "fs:ReadBranch",
                    "fs:CreateBranch",
                    "fs:DeleteBranch",
                    "fs:CreateCommit"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}/branch/*"
            },
            {
                "action": [
                    "fs:ListObjects",
                    "fs:ReadObject",
                    "fs:WriteObject",
                    "fs:DeleteObject"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}/object/*"
            },
            {
                "action": [
                    "fs:ReadTag",
                    "fs:CreateTag",
                    "fs:DeleteTag"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}/tag/*"
            },
            {
                "action": [
                    "fs:ReadConfig"
                ],
                "effect": "allow",
                "resource": "*"
            },
            {
                "action": [
                    "auth:ReadGroup",
                    "auth:AddGroupMember",
                    "auth:RemoveGroupMember"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}-*"
            }
        ]
    }
    """
  end

  def read_write_policy(repo_name) do
    ~s"""
    {
        "id": "#{repo_name}-read-write-policy",
        "statement": [
            {
                "action": [
                    "fs:ReadRepository",
                    "fs:ReadCommit",
                    "fs:ListBranches",
                    "fs:ListTags",
                    "fs:ListObjects",
                    "pr:ReadPullRequest",
                    "pr:WritePullRequest",
                    "pr:ListPullRequests"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}"
            },
            {
                "action": [
                    "fs:RevertBranch",
                    "fs:ReadBranch",
                    "fs:CreateBranch",
                    "fs:DeleteBranch",
                    "fs:CreateCommit"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}/branch/*"
            },
            {
                "action": [
                    "fs:ListObjects",
                    "fs:ReadObject",
                    "fs:WriteObject",
                    "fs:DeleteObject"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}/object/*"
            },
            {
                "action": [
                    "fs:ReadTag",
                    "fs:CreateTag",
                    "fs:DeleteTag"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}/tag/*"
            },
            {
                "action": [
                    "fs:ReadConfig"
                ],
                "effect": "allow",
                "resource": "*"
            }
        ]
    }
    """
  end

  def read_policy(repo_name) do
    ~s"""
    {
        "id": "#{repo_name}-read-policy",
        "statement": [
            {
                "action": [
                    "fs:ReadRepository",
                    "fs:ReadCommit",
                    "fs:ListBranches",
                    "fs:ListTags",
                    "fs:ListObjects",
                    "pr:ReadPullRequest",
                    "pr:WritePullRequest",
                    "pr:ListPullRequests"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}"
            },
            {
                "action": [
                    "fs:ListObjects",
                    "fs:ReadObject"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}/object/*"
            },
            {
                "action": [
                    "fs:ReadTag"
                ],
                "effect": "allow",
                "resource": "arn:lakefs:fs:::repository/#{repo_name}/tag/*"
            }
        ]
    }
    """
  end

  @doc """
  This is the pre-merge hook which can be used to communicate back to a webhook. Defaults on merge back to maine
  """
  def pre_merge_metadata_hook(endpoint, opts \\ []) do
    ~s"""
    name: Metadata Sent to Datahub
    description: sends metadata on to Datahub by triggering Azure Serverless function
    on:
      pre-merge:
        branches:
          - #{Keyword.get(opts, :branch, "main")}
    hooks:
      - id: metadata_send_trigger
        type: webhook
        description: triggering metadata functions
        properties:
          url: "#{endpoint}"
    """
  end
end
