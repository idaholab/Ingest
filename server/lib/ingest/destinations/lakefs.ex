defmodule Ingest.Destinations.Lakefs do
  @moduledoc """
  LakeFS is a simple sdk for the LakeFS system
  """
  def new_client(url, {access_key_id, secret_access_key}) do
    Req.new(base_url: url, auth: {:basic, "#{access_key_id}:#{secret_access_key}"})
  end

  def list_repos(req) do
    case Req.get(req, url: "/api/v1/repositories") do
      {:ok, %{body: %{"results" => results}}} -> {:ok, results}
      {:error, res} -> {:error, res}
    end
  end
end
