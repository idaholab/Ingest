defmodule IngestWeb.TemplatesResourceLive do
  use Backpex.LiveResource,
    layout: {IngestWeb.Layouts, :admin},
    adapter: Backpex.Adapters.Ecto,
    adapter_config: [
      schema: Ingest.Requests.Template,
      repo: Ingest.Repo,
      update_changeset: &Ingest.Requests.Template.changeset/3,
      create_changeset: &Ingest.Requests.Template.changeset/3
    ],
    pubsub: [
      name: Ingest.PubSub,
      topic: "templates",
      event_prefix: "template_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "Template"

  @impl Backpex.LiveResource
  def plural_name, do: "Templates"

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
