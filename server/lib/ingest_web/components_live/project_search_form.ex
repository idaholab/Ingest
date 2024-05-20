defmodule IngestWeb.LiveComponents.ProjectSearchForm do
  @moduledoc """
  projectModal is the modal for creating/editing Data projects. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="space-y-12">
        <form phx-change="search" phx-target={@myself} id="search">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-full">
                <.label for="status-select">
                  Search
                </.label>
                <.input type="text" name="value" value="" />
              </div>
            </div>
          </div>
        </form>
      </div>

      <div :if={@results && @results == []}>
        No Results....
      </div>

      <div>
        <ul :if={@results && @results != []} role="list" class="divide-y divide-gray-100">
          <%= for result <- @results do %>
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">
                    <%= result.name %>
                  </p>
                </div>
              </div>
              <div>
                <span
                  phx-click="add"
                  phx-value-id={result.id}
                  phx-target={@myself}
                  class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/10 cursor-pointer"
                >
                  Add
                </span>
              </div>
            </li>
          <% end %>
        </ul>
      </div>

      <div class="mt-6 flex items-center justify-end gap-x-6">
        <.button
          class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          phx-disable-with="Saving..."
        >
          Save
        </.button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:results, nil)
     |> assign(assigns)}
  end

  @impl true
  def handle_event("search", %{"value" => value}, socket) do
    search(socket, socket.assigns.live_action, value)
  end

  @impl true
  def handle_event("add", %{"id" => id}, socket) do
    add(socket, socket.assigns.live_action, id)
  end

  def add(socket, :search_templates, id) do
    templates = [Ingest.Projects.get_template!(id) | socket.assigns.project.templates]

    Ingest.Projects.update_project_templates(socket.assigns.project, templates)

    {:noreply, socket |> push_patch(to: ~p"/dashboard/projects/#{socket.assigns.project.id}")}
  end

  def add(socket, :search_destinations, id) do
    destinations = [
      Ingest.Destinations.get_destination!(id) | socket.assigns.project.destinations
    ]

    Ingest.Projects.update_project_destinations(socket.assigns.project, destinations)

    {:noreply, socket |> push_patch(to: ~p"/dashboard/projects/#{socket.assigns.project.id}")}
  end

  def search(socket, :search_templates, value) do
    {:noreply,
     socket
     |> assign(
       :results,
       Ingest.Requests.search_templates(value, exclude: socket.assigns.project.templates)
     )}
  end

  def search(socket, :search_destinations, value) do
    {:noreply,
     socket
     |> assign(
       :results,
       Ingest.Destinations.search(value, exclude: socket.assigns.project.destinations)
     )}
  end
end
