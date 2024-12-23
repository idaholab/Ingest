defmodule IngestWeb.LiveComponents.DestinationAddtionalConfigForm do
  @moduledoc """
  This is the LiveComponent for managing the sharing of destinations with other people.
  """

  alias ExAws.Operation.S3
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
              <.input type="text" field={@form[:folder_name]} />
            </div>

            <div class="col-span-full">
              <.label for="status-select">
                Owner Email
              </.label>
              <.input type="text" field={@form[:folder_name]} />
              <p class="text-xs py-2">
                The email address of the repository owner.
              </p>

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
                Integrated Metadata
              </.label>
              <.input type="checkbox" field={@form[:integrated_metadata]} />
              <p class="text-xs">
                Whether or not to use this destination's type native method for storing metadata.
              </p>
            </div>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.button
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            type="submit"
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
  def update(%{destination: destination, destination_member: member} = assigns, socket) do
    config =
      cond do
        member.project_id -> Ingest.Projects.get_project_destination(member.project, destination)
        member.request_id -> Ingest.Requests.get_request_destination(member.request, destination)
        true -> %{}
      end

    changeset =
      case destination.type do
        :lakefs ->
          %LakeFSConfigAdditional{}
          |> LakeFSConfigAdditional.changeset(if config, do: config, else: %{})
          |> Map.put(:action, :validate)

        :azure ->
          %AzureConfigAdditional{}
          |> AzureConfigAdditional.changeset(if config, do: config, else: %{})
          |> Map.put(:action, :validate)

        :s3 ->
          %S3ConfigAdditional{}
          |> S3ConfigAdditional.changeset(if config, do: config, else: %{})
          |> Map.put(:action, :validate)
      end

    {:ok,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(assigns)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    changeset =
      case socket.assigns.destination.type do
        :lakefs ->
          %LakeFSConfigAdditional{}
          |> LakeFSConfigAdditional.changeset(params["lakefs_config_additional"])
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

  @imple true
  def handle_event("save", params, socket) do
    params =
      case socket.assigns.destination.type do
        :lakefs -> params["lakefs_config_additional"]
        :azure -> params["azure_config_additional"]
        :s3 -> params["s3_config_additional"]
      end

    cond do
      socket.assigns.destination_member.request_id ->
        case Ingest.Requests.update_request_destination_config(
               socket.assigns.destination_member,
               params
             ) do
          {1, _request} ->
            {:noreply,
             socket
             |> put_flash(:info, "Destination updated successfully")
             |> push_patch(to: socket.assigns.patch)}

          _ ->
            {:noreply, socket}
        end

      socket.assigns.destination_member.project_id ->
        case Ingest.Projects.update_project_destination_config(
               socket.assigns.destination_member,
               params
             ) do
          {1, _project} ->
            {:noreply,
             socket
             |> put_flash(:info, "Destination updated successfully")
             |> push_patch(to: socket.assigns.patch)}

          _ ->
            {:noreply, socket}
        end
    end
  end
end
