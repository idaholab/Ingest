defmodule IngestWeb.UploadsLive do
  alias Ingest.Requests
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-base font-semibold leading-6 text-gray-900">Recent Project Uploads</h1>
          <p class="mt-2 text-sm text-gray-700">
            A list of projects you've recently uploaded to.
          </p>
        </div>
      </div>
      <div class="mt-8 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8 pb-20 border-b mb-10">
            <.table
              id="requests"
              rows={@requests}
              row_click={fn request -> JS.navigate(~p"/dashboard/uploads/#{request}") end}
            >
              <:col :let={request} label="Project Name">{request.project.name}</:col>
              <:col :let={request} label="Request Name">{request.name}</:col>
              <:col :let={request} label="Request Description">
                {request.description}
              </:col>

              <:action :let={request}>
                <.link
                  navigate={~p"/dashboard/uploads/#{request}"}
                  class="text-indigo-600 hover:text-indigo-900"
                >
                  Upload Data
                </.link>
              </:action>
            </.table>
          </div>
        </div>
      </div>
    </div>
    <div class="mx-auto max-w-lg">
      <div>
        <div class="text-center">
          <.icon name="hero-arrow-up-on-square-stack" class="mx-auto h-12 w-12 text-gray-400" />

          <h2 class="mt-2 text-base font-semibold leading-6 text-gray-900">Upload Data to Project</h2>
          <p class="mt-1 text-sm text-gray-500">
            Search or select a data request by project from the list below to begin uploading data.
          </p>
        </div>
        <form phx-change="search" class="mt-6">
          <label for="email" class="sr-only">Search</label>
          <.input
            type="text"
            name="value"
            value=""
            class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            placeholder="Search Requests by Project"
          />
        </form>
      </div>
      <div class="mt-10">
        <h3 class="text-sm font-medium text-gray-500">Active Data Requests by Project</h3>
        <div :if={@results == [] && @searched}>
          <p class="text-xs italic">No results...</p>
        </div>
        <div :if={@results == [] && !@searched}>
          <p class="text-xs italic">Begin typing to search for active projects or requests..</p>
        </div>
        <ul role="list" class="mt-4 divide-y divide-gray-200 border-b border-t border-gray-200">
          <%= for request <- @results do %>
            <li
              class="flex items-center justify-between space-x-3 py-4"
              phx-click={JS.navigate(~p"/dashboard/uploads/#{request}")}
            >
              <div class="flex min-w-0 flex-1 items-center space-x-3">
                <div class="min-w-0 flex-1">
                  <p class="truncate text-sm font-medium text-gray-900">
                    {request.project.name}
                  </p>
                  <p class="truncate text-sm font-medium text-gray-500">
                    {request.name}
                  </p>
                </div>
              </div>
              <div class="flex-shrink-0">
                <button
                  type="button"
                  class="inline-flex items-center gap-x-1.5 text-sm font-semibold leading-6 text-gray-900"
                  phx-click={JS.navigate(~p"/dashboard/uploads/#{request}")}
                >
                  <svg
                    class="h-5 w-5 text-gray-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                  </svg>
                  Upload Data
                </button>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:section, "uploads")
     |> stream(:requests, [])
     |> assign(:results, [])
     |> assign(:searched, false), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    requests =
      Requests.list_recent_requests(socket.assigns.current_user) ++
        Requests.list_invited_request(socket.assigns.current_user)

    {:noreply,
     socket
     |> assign(:requests, requests)}
  end

  @impl true
  def handle_event("search", %{"value" => value}, socket) do
    {:noreply,
     socket
     |> assign(:searched, true)
     |> assign(
       :results,
       Ingest.Requests.search_requests_by_project(value)
     )}
  end
end
