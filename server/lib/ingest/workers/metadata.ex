defmodule Ingest.Workers.Metadata do
  @moduledoc """
  This worker is in charge of writing an uploads metadata entry to all destinations that exist
  in the request. This gets triggered each time someone submits a section - this is so that we
  can always ensure we're writing at least some metadata to the destination.
  """
  alias Ingest.Destinations.Destination
  alias Ingest.Uploads
  alias Ingest.Uploads.Upload
  alias Ingest.Uploaders.Azure
  alias Ingest.Uploaders.S3
  alias Ingest.Uploaders.Lakefs

  use Oban.Worker, queue: :metadata
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"upload_id" => upload_id} = _args}) do
    # take the upload and load the upload, its request, the requests destinations and the metadata
    upload = Uploads.get_upload!(upload_id)
    upload_path = Uploads.get_upload_path!(upload_id)

    # only write the metadata if we have all of it or it's forced
    if Enum.count(upload.metadatas) ==
         Enum.count(upload.request.templates) + Enum.count(upload.request.project.templates) do
      # build the metadata entry json object
      metadata =
        Jason.encode!(%{
          "id" => upload.id,
          "fileName" => upload.filename,
          "fileType" => upload.ext,
          "lastModified" => upload.updated_at,
          "created" => upload.inserted_at,
          "owner" => %{
            "ingest_id" => upload.user.id,
            "display_name" => Map.get(upload.request.project.user, :name),
            "email" => upload.user.email
          },
          "project" => %{
            "ingest_id" => upload.request.project.id,
            "name" => upload.request.project.name,
            "owner" => %{
              "ingest_id" => upload.request.project.user.id,
              "display_name" => Map.get(upload.request.project.user, :name),
              "email" => upload.request.project.user.email
            }
          },
          "user_provided_metadata" => Enum.map(upload.metadatas, fn m -> m.data end)
        })

      filename = "#{upload_path.path}.m.json"

      # for each destination check to see if we need to use the integrated metadata method - if we do
      # then we only want to write the metadata if all the entries have been submitted as to avoid long jobs
      # and large transfer fees
      statuses =
        Enum.map(
          upload.request.destinations ++ upload.request.project.destinations,
          &destination_metadata_upload(&1, upload, filename, metadata)
        )

      if Enum.member?(statuses, :error) do
        :error
      else
        :ok
      end
    else
      :ok
    end
  end

  defp destination_metadata_upload(
         %Destination{} = destination,
         %Upload{} = upload,
         filename,
         metadata
       ) do
    path = Uploads.get_upload_path(upload)

    case destination.type do
      :azure ->
        if destination.azure_config.integrated_metadata do
          Azure.update_metadata(destination, path.path, %{
            ingest_metadata: Jason.encode!(metadata)
          })
        else
          Azure.upload_full_object(destination, filename, metadata)
        end

      :s3 ->
        if destination.s3_config.integrated_metadata do
          S3.upload_full_object(destination, path.path, [
            {:ingest_metadata, Jason.encode!(metadata)}
          ])
        else
          S3.upload_full_object(destination, filename, metadata)
        end

      :lakefs ->
        if destination.lakefs_config.integrated_metadata do
          Lakefs.update_metadata(
            destination,
            upload.request,
            upload.user,
            path.path,
            [
              {:ingest_metadata, Jason.encode!(metadata)}
            ]
          )
        else
          Lakefs.upload_full_object(
            destination,
            upload.request,
            upload.user,
            filename,
            metadata
          )
        end

      _ ->
        {:error, :unknown_destination_type}
    end
  end
end
