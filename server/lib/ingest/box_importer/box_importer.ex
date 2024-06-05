defmodule Ingest.BoxImporter do
  @moduledoc """
  Implementation for Box Importer in Elixir.
  """
  use GenServer

  alias BoxImporter.Config
  alias BoxImporter.Files

  defmodule State do
    @moduledoc """
    State simply structures the genservers state to make access easier and typchecked.
    """
    defstruct [:config]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %State{
      config: %Config{
        access_token: Keyword.get(opts, :access_token),
        base_service_url: Keyword.get(opts, :base_service_url, "https://api.box.com/2.0")
      }
    })
  end

  def get_file(pid, file_id) do
    GenServer.call(pid, {:get_file, file_id})
  end

  # Server API

  def init(%State{} = state) do
    {:ok, state}
  end

  def handle_call({:get_file, file_id}, _from, %State{config: config} = state) do
    {:reply, Files.get_file(config, file_id), state}
  end
end
