defmodule IngestWeb.ProjectsResourceLive do
  use Backpex.LiveResource,
    adapter: Backpex.Adapters.Ecto,
    adapter_config: [
      schema: Ingest.Projects.Project,
      repo: Ingest.Repo,
      update_changeset: &Ingest.Projects.Project.changeset/3,
      create_changeset: &Ingest.Projects.Project.changeset/3
    ],
    layout: {IngestWeb.Layouts, :admin},
    pubsub: [
      name: Ingest.PubSub,
      topic: "projects",
      event_prefix: "project_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Project"

  @impl Backpex.LiveResource
  def plural_name, do: "Projects"

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
      requests: %{
        module: Backpex.Fields.HasMany,
        label: "Requests",
        display_field: :name,
        live_resource: IngestWeb.RequestResourceLive
      }
    ]
  end
end
