defmodule Ingest.Destinations.Lakefs do
  @moduledoc """
  LakeFS is a simple sdk for the LakeFS system
  """
  def new_client(url, {access_key_id, secret_access_key}, opts \\ []) do
    port = Keyword.get(opts, :port, nil)

    Req.new(
      base_url:
        "#{url}#{if port do
          ":#{port}"
        end}",
      auth: {:basic, "#{access_key_id}:#{secret_access_key}"}
    )
  end

  def list_repos(req) do
    case Req.get(req, url: "/api/v1/repositories") do
      {:ok, %{body: %{"results" => results}}} -> {:ok, results}
      {:error, res} -> {:error, res}
    end
  end

  def list_branches(req, repository) do
    case Req.get(req, url: "/api/v1/repositories/#{URI.encode(repository)}/branches") do
      {:ok, %{body: %{"results" => results}}} -> {:ok, results}
      {:error, res} -> {:error, res}
    end
  end

  def create_branch(req, repository, name, source \\ "main") do
    case Req.post(req,
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
end
