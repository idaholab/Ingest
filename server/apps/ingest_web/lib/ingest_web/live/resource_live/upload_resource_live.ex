defmodule IngestWeb.UploadsResourceLive do
  use Backpex.LiveResource,
    layout: {IngestWeb.Layouts, :admin},
    schema: Ingest.Uploads.Upload,
    repo: Ingest.Repo,
    update_changeset: &Ingest.Uploads.Upload.changeset/3,
    create_changeset: &Ingest.Uploads.Upload.changeset/3,
    pubsub: Ingest.PubSub,
    topic: "uploads",
    event_prefix: "upload_"

  @impl Backpex.LiveResource
  def singular_name, do: "Upload"

  @impl Backpex.LiveResource
  def plural_name, do: "Uploads"

  @impl Backpex.LiveResource
  def fields do
    [
      filename: %{
        module: Backpex.Fields.Text,
        label: "Filename"
      },
      size: %{
        module: Backpex.Fields.Number,
        label: "Size"
      },
      ext: %{
        module: Backpex.Fields.Text,
        label: "Extension"
      },
      user: %{
        module: Backpex.Fields.BelongsTo,
        label: "User Email",
        display_field: :email,
        live_resource: IngestWeb.UsersResourceLive
      },
      request: %{
        module: Backpex.Fields.BelongsTo,
        label: "Originating Request",
        display_field: :name,
        live_resource: IngestWeb.RequestResourceLive
      }
    ]
  end
end
