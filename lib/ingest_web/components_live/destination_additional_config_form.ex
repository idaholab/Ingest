defmodule IngestWeb.LiveComponents.DestinationAddtionalConfigForm do
  @moduledoc """
  This is the LiveComponent for managing the sharing of destinations with other people.
  """

  use IngestWeb, :live_component

  alias Ingest.Destinations.LakeFSConfigAdditional
  alias Ingest.Destinations.AzureConfigAdditional
  alias Ingest.Destinations.S3ConfigAdditional

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} phx-change="validate" phx-target={@myself} id="form" phx-submit="save">
        <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
          <div>
            <h2 class="text-base font-semibold leading-7 text-gray-900">Destination Configuration</h2>
            <p class="mt-1 text-sm leading-6 text-gray-600">
              These are Project or Request specific configuration options for this destination. These are typically optional - if you don't set these values, the defaults from the destination owner will be used.
            </p>
          </div>

          <div
            :if={@destination.type in [:azure, :s3]}
            class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2"
          >
            <div class="col-span-full">
              <.label for="status-select">
                Folder Name
              </.label>
              <.input type="text" field={@form[:folder_name]} />
              <p class="text-xs py-2">
                The name of the root folder the data should be stored in.
              </p>
            </div>

            <div class="col-span-3">
              <.label for="status-select">
                Integrated Metadata
              </.label>
              <.input type="checkbox" field={@form[:integrated_metadata]} />
              <p class="text-xs">
                Whether or not to use this destination's type native method for storing metadata.
              </p>
            </div>
          </div>

          <div
            :if={@destination.type == :lakefs}
            class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2"
          >
            <div class="col-span-full">
              <.label for="status-select">
                Repository Name
              </.label>
              <.input
                type="text"
                field={@form[:repository_name]}
                phx-change="repo_name_change"
                phx-target={@myself}
              />
              <p :if={@slug_repo_name} class="text py-2">
                <b>URL Safe Repository Name:</b> {@slug_repo_name}
              </p>
            </div>

            <div class="col-span-full">
              <.label for="status-select">
                Owner Email
              </.label>
              <.input type="text" field={@form[:repository_owner_email]} />
              <p class="text-xs py-2">
                The email address of the repository owner.
              </p>
            </div>

            <div class="col-span-3">
              <.label for="status-select">
                Create Repository
              </.label>
              <.input type="checkbox" field={@form[:upsert_repository]} />
              <p class="text-xs py-2">
                If checked, create repository if it does not exist. <br />
                <b>
                  Note: this may fail if the repository exists but the credentials provided don't have permissions to see it.
                </b>
              </p>
            </div>

            <div :if={@form[:upsert_repository].value == "true"} class="col-span-3">
              <.label for="status-select">
                Generate Admin Policies
              </.label>
              <.input type="checkbox" field={@form[:generate_permissions]} />
              <p class="text-xs py-2">
                If checked, policies and permissions will be created automatically for this individual to grant them admin privileges on that repository.
              </p>
            </div>

            <div class="col-span-3">
              <.label for="status-select">
                Enable DataHub Integration
              </.label>
              <.input type="checkbox" field={@form[:datahub_integration]} />
              <p class="text-xs">
                Whether or not to enable the DataHub integration through LakeFS's action system.
              </p>
            </div>

            <div class="col-span-3">
              <.label for="status-select">
                Integrated Metadata
              </.label>
              <.input type="checkbox" field={@form[:integrated_metadata]} />
              <p class="text-xs">
                Whether or not to use this destination's type native method for storing metadata.
              </p>
            </div>

            <div :if={@form[:datahub_integration].value == true} class="col-span-3">
              <.label for="status-select">
                DataHub Endpoint
              </.label>
              <.input type="text" field={@form[:datahub_endpoint]} />
            </div>

            <div :if={@form[:datahub_integration].value == true} class="col-span-3">
              <.label for="status-select">
                DataHub Token
              </.label>
              <.input type="text" field={@form[:datahub_token]} />
            </div>
          </div>
        </div>
        <!-- ADDED phx-target={@myself} phx-submit="save" -->A
        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.button
            phx-target={@myself}
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            type="submit"
            phx-submit="save"
            phx-disable-with="Saving..."
          >
            Save
          </.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  # credo:disable-for-next-line
  def update(
        %{
          destination: destination
        } = assigns,
        socket
      ) do
    config =
      cond do
        Map.get(assigns, :project, nil) ->
          Ingest.Projects.get_project_destination(assigns.project, destination).additional_config

        Map.get(assigns, :request, nil) ->
          Ingest.Requests.get_request_destination(assigns.request, destination).additional_config

        true ->
          %{}
      end

    changeset =
      case destination.type do
        :lakefs ->
          %LakeFSConfigAdditional{}
          |> LakeFSConfigAdditional.changeset(if config, do: config, else: %{})

        :azure ->
          %AzureConfigAdditional{}
          |> AzureConfigAdditional.changeset(if config, do: config, else: %{})

        :s3 ->
          %S3ConfigAdditional{}
          |> S3ConfigAdditional.changeset(if config, do: config, else: %{})
      end

    {:ok,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:slug_repo_name, nil)
     |> assign(:upsert_repository, false)
     |> assign(:datahub_checked, false)
     |> assign(assigns)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    changeset =
      case socket.assigns.destination.type do
        :lakefs ->
          %LakeFSConfigAdditional{}
          |> LakeFSConfigAdditional.changeset(params["lake_fs_config_additional"])
          |> Map.put(:action, :validate)

        :azure ->
          %AzureConfigAdditional{}
          |> AzureConfigAdditional.changeset(params["azure_config_additional"])
          |> Map.put(:action, :validate)

        :s3 ->
          %S3ConfigAdditional{}
          |> S3ConfigAdditional.changeset(params["s3_config_additionasl"])
          |> Map.put(:action, :validate)
      end

    {:noreply, socket |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("repo_name_change", params, socket) do
    {:noreply,
     socket
     |> assign(
       :slug_repo_name,
       Slug.slugify(Map.get(params["lake_fs_config_additional"], "repository_name", ""))
     )}
  end

  @impl true
  def handle_event("save", params, socket) do
    changeset =
      case socket.assigns.destination.type do
        :lakefs ->
          %LakeFSConfigAdditional{}
          |> LakeFSConfigAdditional.changeset(params["lake_fs_config_additional"])
          |> Map.put(:action, :validate)

        :azure ->
          %AzureConfigAdditional{}
          |> AzureConfigAdditional.changeset(params["azure_config_additional"])
          |> Map.put(:action, :validate)

        :s3 ->
          %S3ConfigAdditional{}
          |> S3ConfigAdditional.changeset(params["s3_config_additionasl"])
          |> Map.put(:action, :validate)
      end

    if changeset.errors != [] do
      {:noreply, socket |> assign(:form, to_form(changeset))}
    else
      params =
        case socket.assigns.destination.type do
          :lakefs ->
            params["lake_fs_config_additional"]
            |> Map.replace(
              "repository_name",
              Slug.slugify(Map.get(params["lake_fs_config_additional"], "repository_name", ""))
            )

          :azure ->
            params["azure_config_additional"]

          :s3 ->
            params["s3_config_additional"]
        end

      updated =
        Ingest.Destinations.update_destination_members_additional_config(
          socket.assigns.destination_member,
          params
        )

      if updated > 0 do
        # we kick off an Oban job to async run any configuration needed on the member
        %{destination_member_id: socket.assigns.destination_member.id}
        |> Ingest.Workers.Destination.new()
        |> Oban.insert()

        {:noreply,
         socket
         |> put_flash(:info, "Destination Configuration updated successfully")
         |> push_patch(to: socket.assigns.patch)}
      else
        {:noreply,
         socket
         |> put_flash(:error, "Unable to update Destination Configration")
         |> push_patch(to: socket.assigns.patch)}
      end
    end
  end
end
