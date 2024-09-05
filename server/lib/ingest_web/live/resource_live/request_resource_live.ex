defmodule IngestWeb.RequestResourceLive do
  use Backpex.LiveResource,
    layout: {IngestWeb.Layouts, :admin},
    schema: Ingest.Requests.Request,
    repo: Ingest.Repo,
    update_changeset: &Ingest.Requests.Request.changeset/3,
    create_changeset: &Ingest.Requests.Request.changeset/3,
    pubsub: Ingest.PubSub,
    topic: "requests",
    event_prefix: "request_"

  @impl Backpex.LiveResource
  def singular_name, do: "Request"

  @impl Backpex.LiveResource
  def plural_name, do: "Requests"

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name"
      },
      description: %{
        module: Backpex.Fields.Text,
        label: "Description"
      },
      status: %{
        module: Backpex.Fields.Select,
        label: "Status",
        options: [Draft: :draft, Published: :published]
      },
      visibility: %{
        module: Backpex.Fields.Select,
        label: "Visibility",
        options: [Public: :public, Private: :private, Internal: :internal]
      },
      project: %{
        module: Backpex.Fields.BelongsTo,
        label: "Project",
        display_field: :name,
        live_resource: IngestWeb.ProjectsResourceLive
      },
      user: %{
        module: Backpex.Fields.BelongsTo,
        label: "User Email",
        display_field: :email,
        live_resource: IngestWeb.UsersResourceLive
      }
    ]
  end
end
