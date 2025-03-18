defmodule Ingest.Uploaders.MultiDestinationWriter do
  @moduledoc """
  This is the primary implementation of LiveView.UploadWriter. This accepts multiple destinations for different
  types and uploads chunks to each of the included destinations and their configurations. See the individual
  files for each storage provider implementation.
  """
  @behaviour Phoenix.LiveView.UploadWriter
  alias Ingest.Uploaders.Azure
  alias Ingest.Uploaders.S3
  alias Ingest.Uploaders.Lakefs
  alias Ingest.Uploaders.DeepLynx

  @impl true
  def init(opts) do
    # should be called in context of a user session - fail if not
    user = Keyword.fetch!(opts, :user)

    # original filename indicates this should be put in a folder with the original file's name as "supporting uploads"
    original_filename = Keyword.get(opts, :original_filename, nil)

    # we try to put the caller in charge of ensuring no clashes with the file structure
    # we don't want to make many assumptions in the uploader - if there are specifics that
    # have to happen we leave it to the individual implementation
    filename = Keyword.fetch!(opts, :filename)

    # Uploads should always belong to a request
    request = Keyword.fetch!(opts, :request)

    # %Destination{}[] we don't need to overwrite the original destination because each of
    # them already have their configs stored within them - and because this is the UploadWriter
    # we know this is using the staging environment of each
    destinations =
      Keyword.fetch!(opts, :destinations)
      |> Enum.map(fn d ->
        {d, %{request: request, user: user, original_filename: original_filename}}
      end)

    {statuses, destinations} =
      Enum.map(destinations, &init_chunk_upload(&1, filename))
      |> Enum.unzip()

    if Enum.member?(statuses, :error) do
      {:error, destinations, %{}}
    else
      {:ok,
       %{
         chunk: 1,
         destinations: destinations,
         filename: filename,
         original_filename: original_filename
       }}
    end
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
      |> Enum.unzip()

    if Enum.member?(statuses, :error) do
      {:error, destinations, state}
    else
      {:ok,
       %{
         state
         | chunk: state.chunk + 1,
           destinations: destinations,
           filename: state.filename,
           original_filename: state.original_filename
       }}
    end
  end

  @impl true
  def close(state, reason) do
    case reason do
      :done ->
        {statuses, destinations} =
          Enum.map(state.destinations, &finalize_upload(&1, state.filename))
          |> Enum.unzip()

        if Enum.member?(statuses, :error) do
          {:error, destinations}
        else
          {:ok,
           %{
             filename: state.filename,
             destinations: destinations,
             original_filename: state.original_filename
           }}
        end

      :cancel ->
        {:error, :cancelled}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # returns {:ok, {destination, state}} or {:error, error}
  # we return the full destination so we can simply rebuild the list
  # without having to keep track of the association between state and destination
  defp init_chunk_upload({destination, state}, filename) do
    case destination.type do
      :azure ->
        Azure.init(destination, filename, state, original_filename: state.original_filename)

      :s3 ->
        S3.init(destination, filename, state, original_filename: state.original_filename)

      :lakefs ->
        Lakefs.init!(destination, filename, state, original_filename: state.original_filename)

      :deeplynx ->
        DeepLynx.init(destination, filename, state, original_filename: state.original_filename)

      _ ->
        {:error, :unknown_destination_type}
    end
  end

  # returns {:ok, {destination, state}} or {:error, error}
  # we return the full destination so we can simply rebuild the list
  # without having to keep track of the association between state and destination
  defp upload_chunk({destination, state}, filename, data) do
    case destination.type do
      :azure ->
        Azure.upload_chunk(destination, filename, state, data,
          original_filename: state.original_filename
        )

      :s3 ->
        S3.upload_chunk(destination, filename, state, data,
          original_filename: state.original_filename
        )

      :lakefs ->
        Lakefs.upload_chunk(destination, filename, state, data,
          original_filename: state.original_filename
        )

      :deeplynx ->
        DeepLynx.upload_chunk(destination, filename, state, data,
          original_filename: state.original_filename
        )

      _ ->
        {:error, :unknown_destination_type}
    end
  end

  # returns {:ok, state} or {:error, error}
  defp finalize_upload({destination, state}, filename) do
    case destination.type do
      :azure ->
        Azure.commit(destination, filename, state, original_filename: state.original_filename)

      :s3 ->
        S3.commit(destination, filename, state, original_filename: state.original_filename)

      :lakefs ->
        Lakefs.commit(destination, filename, state, original_filename: state.original_filename)

      :deeplynx ->
        DeepLynx.commit(destination, filename, state, original_filename: state.original_filename)

      _ ->
        {:error, :unknown_destination_type}
    end
  end
end
