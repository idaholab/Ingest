defmodule AzureStorage do
  @moduledoc """
  Implementation for Azure's Blob Storage in Elixir.
  """
  use GenServer
  alias AzureStorage.Config
  alias AzureStorage.Container
  alias AzureStorage.Blob

  defmodule State do
    @moduledoc """
    State simply structures the genservers state to make access easier and typchecked.
    """
    defstruct [:config, :container]
  end

  # Client
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %State{
      config: %Config{
        account_name: Keyword.get(opts, :account_name),
        account_key: Keyword.get(opts, :account_key),
        account_connection_string: Keyword.get(opts, :account_connection_string),
        ssl: Keyword.get(opts, :ssl, true),
        base_service_url: Keyword.get(opts, :base_service_url, "blob.core.windows.net")
      }
    })
  end

  def new_container(pid, name) do
    GenServer.call(pid, {:new_container, name})
  end

  def new_blob(pid, %Container{} = container, name) do
    GenServer.call(pid, {:new_blob, container, name})
  end

  def put_blob(pid, %Container{} = container, blob_name, data, opts \\ []) do
    GenServer.call(pid, {:upload_blob, container, blob_name, data, opts})
  end

  def put_block(pid, %Blob{} = blob, data, opts \\ []) do
    GenServer.call(pid, {:upload_block, blob, data, opts})
  end

  def commit_blocklist(pid, %Blob{} = blob, blocklist, opts \\ []) when is_list(blocklist) do
    GenServer.call(pid, {:commit_blocklist, blob, blocklist, opts})
  end

  # Server (callbacks)
  @impl true
  def init(%State{} = state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:new_container, container_name}, _from, state) do
    {:reply, {:ok, Container.new(container_name)}, state}
  end

  @impl true
  def handle_call({:new_blob, %Container{} = container, blob_name}, _from, state) do
    {:reply, {:ok, Blob.new(container, blob_name)}, state}
  end

  @impl true
  def handle_call(
        {:upload_blob, %Container{} = container, blob_name, data, opts},
        _from,
        %State{} = state
      ) do
    case(container |> Blob.new(blob_name) |> Blob.put_blob(state.config, data, opts)) do
      {:ok, blob} ->
        {:reply, {:ok, blob}, state}

      {:error, %Req.Response{} = resp} ->
        handle_response(resp, state)

      _ ->
        {:reply, {:error, :reponse_not_recognized}, state}
    end
  end

  @impl true
  def handle_call(
        {:upload_block, %Blob{} = blob, data, opts},
        _from,
        %State{} = state
      ) do
    case(blob |> Blob.put_block(state.config, data, opts)) do
      {:ok, block_id} ->
        {:reply, {:ok, block_id}, state}

      {:error, %Req.Response{} = resp} ->
        handle_response(resp, state)

      _ ->
        {:reply, {:error, :reponse_not_recognized}, state}
    end
  end

  @impl true
  def handle_call(
        {:commit_blocklist, %Blob{} = blob, blocklist, opts},
        _from,
        %State{} = state
      ) do
    case(blocklist |> Blob.put_block_list(blob, state.config, opts)) do
      {:ok, _nil} ->
        {:reply, {:ok, nil}, state}

      {:error, %Req.Response{} = resp} ->
        handle_response(resp, state)

      _ ->
        {:reply, {:error, :reponse_not_recognized}, state}
    end
  end

  defp handle_response(%Req.Response{} = resp, state) do
    cond do
      400 = resp.status -> {:reply, {:error, :bad_request}, state}
      401 = resp.status -> {:reply, {:error, :unauthorized}, state}
      404 = resp.status -> {:reply, {:error, :not_found}, state}
      true -> {:reply, {:error, :uknown_error}, state}
    end
  end
end
