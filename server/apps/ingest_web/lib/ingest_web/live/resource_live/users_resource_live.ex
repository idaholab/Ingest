defmodule IngestWeb.UsersResourceLive do
  use Backpex.LiveResource,
    adapter: Backpex.Adapters.Ecto,
    adapter_config: [
      schema: Ingest.Accounts.User,
      repo: Ingest.Repo,
      update_changeset: &Ingest.Accounts.User.backpex_changeset/3,
      create_changeset: &Ingest.Accounts.User.backpex_changeset/3
    ],
    layout: {IngestWeb.Layouts, :admin},
    pubsub: [
      name: Ingest.PubSub,
      topic: "users",
      event_prefix: "user_"
    ]

  @impl Backpex.LiveResource
  def singular_name, do: "User"

  @impl Backpex.LiveResource
  def plural_name, do: "Users"

  @impl Backpex.LiveResource
  def fields do
    [
      name: %{
        module: Backpex.Fields.Text,
        label: "Name"
      },
      email: %{
        module: Backpex.Fields.Text,
        label: "Email"
      },
      roles: %{
        module: Backpex.Fields.Select,
        label: "Role",
        options: [Admin: :admin, Manager: :manager, Member: :member]
      }
    ]
  end
end
