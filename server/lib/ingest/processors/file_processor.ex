defmodule Ingest.Processors.FileProcessor do
  @moduledoc """
  This is the processor used to handle files from the LakeFS merge event.
  """

  # we work with both DataHub and LakeFS, we technically don't need to alias them here
  # but I like telling users what we're working with later on at the top of the file
  alias Ingest.DataHub
  alias Ingest.LakeFS

  # because of DataHub's upsert functionality, we don't need to do anything special on update vs. create
  # as we'll do the same things for both
  def process(repo, ref, %{"path" => path} = _result) do
    # first just create the entry in case we have nothing else to send about it
    {:ok, _created} =
      DataHub.create_dataset_event(dataset_path(repo, path), "lakefs") |> DataHub.send_event()

    # set the download linke
    {:ok, _sent} =
      DataHub.create_dataset_event(:download_link, dataset_path(repo, path), "lakefs",
        repo: repo,
        branch: "main",
        endpoint: Application.get_env(:ingest, :lakefs)[:url],
        filename: path
      )
      |> DataHub.send_event()

    # first we need to pull the metadata out if it exists
    {:ok, metadata} = LakeFS.download_metadata(repo, ref, path)

    if Map.get(metadata, "metadata", nil) do
      Enum.each(metadata["metadata"], fn {k, v} ->
        # right now we only support ingest tagged metadata
        if k |> String.downcase() |> String.contains?("ingest_metadata") do
          # we have to double decode due to how it's stored as a string
          data = v |> Jason.decode!() |> Jason.decode!()

          :ok = send_metadata(repo, path, data)
        end
      end)
    end

    # TODO: add the CSV and Parquet processing here in just a few minutes

    {:ok, :processed}
  end

  # simple delete from DataHub on file delete, don't need to do anything else....yet
  def process_delete(repo, _ref, %{"path" => path} = _result) do
    DataHub.delete_dataset(dataset_path(repo, path), "lakefs")
  end

  # updates all the metadata for an object in DataHub from the Ingest metadata
  # note that metadata might be nil
  defp send_metadata(repo, path, metadata) when is_map(metadata) do
    # first update the owner
    {:ok, _sent} =
      DataHub.create_dataset_event(:owners, dataset_path(repo, path), "lakefs",
        owners: [metadata["owner"]["email"]]
      )
      |> DataHub.send_event()

    # next update the project
    {:ok, _sent} =
      DataHub.create_dataset_event(:project, dataset_path(repo, path), "lakefs",
        name: metadata["project"]["name"]
      )
      |> DataHub.send_event()

    # finally set the custom properties as a merge of all the user provided metadata
    {:ok, _sent} =
      DataHub.create_dataset_event(:properties, dataset_path(repo, path), "lakefs",
        name: metadata["fileName"],
        custom:
          metadata["user_provided_metadata"] |> Enum.reduce(fn m, acc -> Map.merge(acc, m) end)
      )
      |> DataHub.send_event()

    {:ok, :sent}
  end

  defp dataset_path(repo, path) do
    "#{repo}.#{String.replace(Path.basename(path), "/", ".")}"
  end
end
