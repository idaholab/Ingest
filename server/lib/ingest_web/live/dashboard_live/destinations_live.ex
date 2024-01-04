defmodule IngestWeb.DestinationsLive do
  @moduledoc """
  The destinations live component is in charge of handling both the shared destinations created by an administrator
  such as the Project Alexandria storage for NA-22 data or INL HPC, and the shared/owned Ingest Clients known by
  the user. This is the entry point for managing your data destinations prior to hooking them up to a data request.
  """
  alias Ingest.Destinations.Client
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={!@destinations || Enum.empty?(@destinations)} class="text-center">
        <.icon name="hero-folder-plus" class="mx-auto h-12 w-12 text-gray-400" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No destinations</h3>
        <p class="mt-1 text-sm text-gray-500">Get started by creating a new destination.</p>
        <.link
          patch={~p"/dashboard/destinations/new"}
          type="button"
          class="mt-5 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          <.icon name="hero-plus" /> New Destination
        </.link>
      </div>

      <div :if={@destinations && !Enum.empty?(@destinations)} class="px-4 sm:px-6 lg:px-8">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-gray-900">Data Destinations</h1>
            <p class="mt-2 text-sm text-gray-700">
              A list of all the destinations. A data destination is the location your data will be moved to after a user uploads them via a Data Request.
            </p>
          </div>
          <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
            <div class="mt-6">
              <.link patch={~p"/dashboard/destinations/new"}>
                <button
                  type="button"
                  class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  <.icon name="hero-plus" /> New Destination
                </button>
              </.link>
            </div>
          </div>
        </div>
        <div class="mt-8 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <.table
                id="destinations"
                rows={@streams.destinations}
                row_click={
                  fn {_id, destination} -> JS.navigate(~p"/dashboard/destinations/#{destination}") end
                }
              >
                <:col :let={{_id, destination}} label="Name"><%= destination.name %></:col>
                <:col :let={{_id, destination}} label="Type"><%= destination.type %></:col>

                <:action :let={{_id, destination}}>
                  <.link
                    navigate={~p"/dashboard/destinations/#{destination}"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Show
                  </.link>
                </:action>
                <:action :let={{id, destination}}>
                  <.link
                    class="text-red-600 hover:text-red-900"
                    phx-click={JS.push("delete", value: %{id: destination.id}) |> hide("##{id}")}
                    data-confirm="Are you sure?"
                  >
                    Delete
                  </.link>
                </:action>
              </.table>
            </div>
          </div>
        </div>
      </div>
      <!--
      <.modal
        :if={@live_action in [:new]}
        id="destination_modal"
        show
        on_cancel={JS.patch(~p"/dashboard/destinations")}
      >
        <.live_component
          live_action={@live_action}
          destination_form={@destination_form}
          destination={@destination}
          module={IngestWeb.LiveComponents.destinationForm()}
          id="destination-modal-component"
          current_user={@current_user}
        />
      </.modal>
      -->
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       :destinations,
       Ingest.Destinations.list_own_destinations(socket.assigns.current_user)
     )
     |> stream(
       :destinations,
       Ingest.Destinations.list_own_destinations(socket.assigns.current_user)
     )
     |> assign(:section, "destinations"), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :register_client, %{"client_id" => client_id}) do
    socket
    |> assign(:page_title, "Register")
    |> assign(:client_form, %Client{} |> Ecto.Changeset.change() |> to_form())
    |> assign(:client, %Client{owner_id: socket.assigns.current_user.id, id: client_id})
  end

  # need to cover the index action TODO: find a better way of streamlining this
  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Data Destinations")
  end
end
