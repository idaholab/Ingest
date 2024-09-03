defmodule IngestWeb.ProjectsResourceLive do
  use Backpex.LiveResource,
    layout: {IngestWeb.Layouts, :admin},
    schema: Ingest.Projects.Project,
    repo: Ingest.Repo,
    update_changeset: &Ingest.Projects.Project.changeset/3,
    create_changeset: &Ingest.Projects.Project.changeset/3,
    pubsub: Ingest.PubSub,
    topic: "projects",
    event_prefix: "project_"

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
      }
    ]
  end
end
