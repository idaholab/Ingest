defmodule Ingest.Destinations.LakefsClient do
  @moduledoc """
  This is a reusable client for communicating with the LakeFS API.
  """

  @enforce_keys [:endpoint]
  defstruct [:endpoint, :auth, plug: nil]

  @doc """
  Initializes a new LakeFS Client with an endpoint and optional options.

  ## Examples

      iex> Ingest.Destinations.LakefsClient.new("http://localhost:8000", access_key: "my_key", secret_key: "my_secret")
      {:ok, %Ingest.Destinations.LakefsClient{}}
  """
  def new(endpoint, opts \\ []) do
    case URI.new(endpoint) do
      {:ok, uri} ->
        auth = set_auth(opts[:access_key], opts[:secret_key])

        {:ok, %__MODULE__{
          endpoint: uri,
          auth: auth,
          plug: Keyword.get(opts, :plug)
        }}

      _ ->
        {:error, "Unable to parse endpoint"}
    end
  end

  def new!(endpoint, opts \\ []) do
    {:ok, client} = new(endpoint, opts)
    client
  end

  @doc """
  Lists all repositories on the LakeFS server.
  """
  def list_repos(%__MODULE__{} = client) do
    Req.get(
      "#{client.endpoint}/api/v1/repositories",
      auth: client.auth,
      plug: client.plug
    )
    |> format_response()
  end

  @doc """
  Lists all branches in a given repository.
  """
  def list_branches(%__MODULE__{} = client, repository) do
    Req.get(
      "#{client.endpoint}/api/v1/repositories/#{URI.encode(repository)}/branches",
      auth: client.auth,
      plug: client.plug
    )
    |> format_response()
  end

  @doc """
  Creates a new branch in a given repository.
  """
  def create_branch(%__MODULE__{} = client, repository, name, source \\ "main") do
    Req.post(
      "#{client.endpoint}/api/v1/repositories/#{URI.encode(repository)}/branches",
      auth: client.auth,
      json: %{
        name: name,
        source: source
      },
      plug: client.plug
    )
    |> format_response(expected_status_code: 201)
  end

  defp format_response(resp, opts \\ []) do
    expected_status_code = Keyword.get(opts, :expected_status_code, 200)

    case resp do
      {:ok, %{status: ^expected_status_code, body: body}} ->
        {:ok, body}

      {:ok, %{body: body}} ->
        {:error, :unexpected_status_code, body}

      _ ->
        {:error, :req_error}
    end
  end

  defp set_auth(access_key, secret_key) do
    if access_key && secret_key do
      {:basic, "#{access_key}:#{secret_key}"}
    else
      nil
    end
  end
end
