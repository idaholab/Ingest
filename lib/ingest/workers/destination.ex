defmodule Ingest.Workers.Destination do
  @moduledoc """
  This worker is used for running any additional steps when a destination is saved
  or configured for a request/project. We do this as an async job - because in the case
  of some destination types, like LakeFS - we might need to perform actions that the user
  shouldn't need to wait for - or which might be prone to high rates of failure. So we hide
  and log any errors through the error logger system.
  """

  alias Ingest.Destinations
  alias Ingest.LakeFS
  alias Ingest.Destinations.Destination

  use Oban.Worker, queue: :destinations
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"destination_member_id" => destination_member_id} = _args}) do
    member = Destinations.get_destination_member!(destination_member_id)

    configure_destination(member.destination)
  end

  def perform(%Oban.Job{args: %{"destination_id" => destination_id} = _args}) do
    configure_destination(Destinations.get_destination!(destination_id))
  end

  @doc """
  For LakeFS we do things like create repositories if none already exist, setup admin policies
  and groups etc. This is especially important when we need to configure for a request. Because
  this is being called by the member id above, it might have loaded additional configuration that
  needs to be completed.
  """
  def configure_destination(%Destination{type: :lakefs} = destination)
      when is_nil(destination.additional_config) do
    client =
      LakeFS.new!(
        %URI{
          host: destination.lakefs_config.base_url,
          port: destination.lakefs_config.port,
          scheme: if(destination.lakefs_config.ssl, do: "https", else: "http")
        },
        access_key: destination.lakefs_config.access_key_id,
        secret_access_key: destination.lakefs_config.secret_access_key
      )

    repo =
      case LakeFS.get_repo(client, Slug.slugify(destination.lakefs_config.repository)) do
        {:ok, repo} ->
          repo["id"]

        _ ->
          {:ok, repo} =
            LakeFS.create_repo(client, Slug.slugify(destination.lakefs_config.repository),
              storage_namespace:
                "#{destination.lakefs_config.storage_namespace}-#{Slug.slugify(destination.lakefs_config.repository)}"
            )

          repo["id"]
      end

    # create the user, if we error, we assume it's because it exists already - any future calls
    # will fail if this assumption is untrue, and we don't need to be gentle handling errors
    case LakeFS.create_repo(client, destination.user.email, invite_user: true) do
      {:ok, user} -> user.id
      _ -> destination.user.email
    end

    # once everything is done, we can set the branch protection
    LakeFS.protect_branch(client, repo, "main")
  end

  # additional configuration always outweighs the original configuration
  def configure_destination(%Destination{type: :lakefs} = destination) do
    client =
      LakeFS.new!(
        %URI{
          host: destination.lakefs_config.base_url,
          port: destination.lakefs_config.port,
          scheme: if(destination.lakefs_config.ssl, do: "https", else: "http")
        },
        access_key: destination.lakefs_config.access_key_id,
        secret_access_key: destination.lakefs_config.secret_access_key
      )

    # we need to

    # create the repo, if we error, we assume it's because it exists already - any future calls
    # will fail if this assumption is untrue, and we don't need to be gentle handling errors
    repo =
      case LakeFS.get_repo(client, destination.additional_config["repository_name"]) do
        {:ok, repo} ->
          repo["id"]

        _ ->
          {:ok, repo} =
            LakeFS.create_repo(client, destination.additional_config["repository_name"],
              storage_namespace:
                "#{destination.lakefs_config.storage_namespace}/#{destination.additional_config["repository_name"]}"
            )

          repo["id"]
      end

    account =
      Ingest.Accounts.get_user_by_email(destination.additional_config["repository_owner_email"])

    user_id =
      if account.identity_provider_id do
        account.identity_provider_id
      else
        account.id
      end

    # create the user, if we error, we assume it's because it exists already - any future calls
    # will fail if this assumption is untrue, and we don't need to be gentle handling errors
    user =
      case LakeFS.create_user(
             client,
             user_id,
             email: destination.additional_config["repository_owner_email"],
             invite_user: true
           ) do
        {:ok, user} -> user.id
        _ -> destination.additional_config["repository_owner_email"]
      end

    # generate the groups and policies so we can add the repo owner to the admin group
    if destination.additional_config["generate_permissions"] == "true" do
      {:ok, admin_policy} =
        LakeFS.create_policy(
          client,
          LakeFS.admin_policy(destination.additional_config["repository_name"])
        )

      {:ok, read_write_policy} =
        LakeFS.create_policy(
          client,
          LakeFS.read_write_policy(destination.additional_config["repository_name"])
        )

      {:ok, read_policy} =
        LakeFS.create_policy(
          client,
          LakeFS.read_policy(destination.additional_config["repository_name"])
        )

      {:ok, admin_group} =
        LakeFS.create_group(client, "#{destination.additional_config["repository_name"]}-admin")

      {:ok, read_group} =
        LakeFS.create_group(client, "#{destination.additional_config["repository_name"]}-read")

      {:ok, read_write_group} =
        LakeFS.create_group(
          client,
          "#{destination.additional_config["repository_name"]}-read-write"
        )

      :ok = LakeFS.attach_group_policy(client, admin_group["id"], admin_policy["id"])
      :ok = LakeFS.attach_group_policy(client, read_group["id"], read_policy["id"])
      :ok = LakeFS.attach_group_policy(client, read_write_group["id"], read_write_policy["id"])
      LakeFS.attach_user_group(client, admin_group["id"], user)
    end

    # if we have the datahub_integration we need to put the datahub action into the repository and commit
    if destination.additional_config["datahub_integration"] == "true" do
      endpoint = Application.get_env(:ingest, IngestWeb.Endpoint)[:url]

      :ok =
        LakeFS.put_object(
          client,
          repo,
          "_lakefs_actions/actions.yaml",
          LakeFS.pre_merge_metadata_hook(
            URI.to_string(%URI{
              host: endpoint[:host],
              port: endpoint[:port],
              scheme: endpoint[:scheme],
              path: "/destinations/#{destination.id}/lakefs_action",
              # we encode the datahub endpoint into the URL so we can search for the token by URL and destination
              # later on
              query:
                "datahub_url=#{URI.encode(destination.additional_config["datahub_endpoint"])}"
            })
          )
        )

      # we have to commit the actions before they work
      {:ok, _commit} = LakeFS.commit_changes(client, repo, message: "initial commit")
    end

    # once everything is done, we can set the branch protection
    LakeFS.protect_branch(client, repo, "main")
  end

  def configure_destination(destination) do
    :ok
  end
end
