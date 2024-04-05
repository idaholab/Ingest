defmodule Ingest.Uploaders.MultiDestinationWriter do
  @moduledoc """
  This is the primary implemenation of LiveView.UploadWriter. This accepts multiple destinations for different
  types and uploads chunks to each of the included destinations and their configurations. See the individual
  files for each storage provider implementation.
  """
  @behaviour Phoenix.LiveView.UploadWriter
  alias Ingest.Uploaders.Azure

  @impl true
  def init(opts) do
    # we try to put the caller in charge of ensuring no clashes with the file structure
    # we don't want to make many assumptions in the uploader - if there are specifics that
    # have to happen we leave it to the individual implementation
    filename = Keyword.fetch!(opts, :filename)
    # %Destination{}[] we don't need to overwrite the original destination because each of
    # them already have their configs stored within them - and because this is the UploadWriter
    # we know this is using the staging environment of each
    destinations = Keyword.fetch!(opts, :destinations)

    # keep track of the parts of each individual part information
    {:ok,
     %{chunk: 1, filename: filename, destinations: Enum.map(destinations, fn d -> {d, []} end)}}
  end

  @impl true
  def meta(state) do
    state
  end

  @impl true
  def write_chunk(data, state) do
    # build a list of Tasks to await - the return will take the place
    # of the original destination list - all needed information for writing a chunk
    # should be found on the destination and as part of the user provided filename
    {statuses, destinations} =
      Enum.map(state.destinations, &upload_chunk(&1, state.filename, data))
      |> Enum.map(&Task.await/1)
      |> Enum.unzip()

    if Enum.member?(statuses, :error) do
      {:error, destinations, state}
    else
      {:ok,
       %{state | chunk: state.chunk + 1, destinations: destinations, filename: state.filename}}
    end
  end

  @impl true
  def close(state, reason) do
    case reason do
      :done ->
        {statuses, destinations} =
          Enum.map(state.destinations, &finalize_upload(&1, state.filename))
          |> Enum.map(&Task.await/1)
          |> Enum.unzip()

        if Enum.member?(statuses, :error) do
          {:error, destinations}
        else
          {:ok,
           %{state | chunk: state.chunk + 1, destinations: destinations, filename: state.filename}}
        end

      :cancel ->
        {:error, :cancelled}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp upload_chunk({destination, parts}, filename, data) do
    Task.Supervisor.async(:upload_tasks, fn ->
      case destination.type do
        :azure -> Azure.upload_chunk(destination, filename, parts, data)
        _ -> {:error, :unknown_destination_type}
      end
    end)
  end

  defp finalize_upload({destination, parts}, filename) do
    Task.Supervisor.async(:upload_tasks, fn ->
      case destination.type do
        :azure -> Azure.commit_blocklist(destination, filename, parts)
        _ -> {:error, :unknown_destination_type}
      end
    end)
  end
end
