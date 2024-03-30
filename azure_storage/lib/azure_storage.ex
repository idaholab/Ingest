defmodule AzureStorage do
  @moduledoc """
  Implementation for Azure's Blob Storage in Elixir.
  """
  use GenServer
  alias AzureStorage.Config

  # Client
  def start_link(default) when is_map(default) do
    GenServer.start_link(__MODULE__, default)
  end

  # Server (callbacks)
  @impl true
  def init(%Config{} = config) do
    {:ok, %{config: config}}
  end

  @impl true
  def handle_call({:upload_blob, _req}, _from, %{:config => _config} = state) do
    # do upload work using config stored in state
    {:reply, nil, state}
  end
end
