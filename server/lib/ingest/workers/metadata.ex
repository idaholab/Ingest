defmodule Ingest.Workers.Metadata do
  @moduledoc """
  This worker is in charge of writing an uploads metadata entry to all destinations that exist
  in the request. This gets triggered each time someone submits a section - this is so that we
  can always ensure we're writing at least some metadata to the destination.
  """
  alias Ingest.Uploads
  alias Ingest.Uploaders.Azure
  alias Ingest.Uploaders.S3
  alias Ingest.Uploaders.Lakefs

  use Oban.Worker, queue: :metadata
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"upload_id" => upload_id} = _args}) do
    # take the upload and load the upload, its request, the requests destinations and the metadata
    upload = Uploads.get_upload!(upload_id)
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
          "display_name" => upload.user.name,
          "email" => upload.user.email
        },
        "project" => %{
          "ingest_id" => upload.request.project.id,
          "name" => upload.request.project.name,
          "owner" => %{
            "ingest_id" => upload.request.project.user.id,
            "display_name" => upload.request.project.user.name,
            "email" => upload.request.project.user.email
          }
        },
        "user_provided_metadata" => Enum.map(upload.metadatas, fn m -> m.data end)
      })

    filename = "#{upload.filename}_metadata.json"

    for destination <- upload.request.destinations do
      case destination.type do
        :azure ->
          Azure.upload_full_object(destination, filename, metadata)

        :s3 ->
          S3.upload_full_object(destination, filename, metadata)

        :lakefs ->
          Lakefs.upload_full_object(
            destination,
            upload.request,
            upload.user,
            filename,
            metadata
          )

        _ ->
          {:error, :unknown_destination_type}
      end
    end

    :ok
  end
end
