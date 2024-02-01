defmodule IngestWeb.UploadsLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-base font-semibold leading-6 text-gray-900">Recent Project Uploads</h1>
          <p class="mt-2 text-sm text-gray-700">
            A list of requests you've recently uploaded to.
          </p>
        </div>
      </div>
      <div class="mt-8 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8 pb-20 border-b mb-10">
            <.table
              id="requests"
              rows={@streams.requests}
              row_click={fn {_id, request} -> JS.navigate(~p"/dashboard/requests/#{request}") end}
            >
              <:col :let={{_id, request}} label="Name"><%= request.name %></:col>
              <:col :let={{_id, request}} label="Project"><%= request.project.name %></:col>
              <:col :let={{_id, request}} label="Description">
                <%= request.description %>
              </:col>

              <:col :let={{_id, request}} label="Status"><%= request.status %></:col>

              <:action :let={{_id, request}}>
                <.link
                  navigate={~p"/dashboard/requests/#{request}"}
                  class="text-indigo-600 hover:text-indigo-900"
                >
                  Show
                </.link>
              </:action>
              <:action :let={{id, request}}>
                <.link
                  class="text-red-600 hover:text-red-900"
                  phx-click={JS.push("delete", value: %{id: request.id}) |> hide("##{id}")}
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
    <div class="mx-auto max-w-lg">
      <div>
        <div class="text-center">
          <.icon name="hero-arrow-up-on-square-stack" class="mx-auto h-12 w-12 text-gray-400" />

          <h2 class="mt-2 text-base font-semibold leading-6 text-gray-900">Upload Data to Request</h2>
          <p class="mt-1 text-sm text-gray-500">
            Search or select a data request from the list below to begin uploading data to project it's attached to.
          </p>
        </div>
        <form action="#" class="mt-6 flex">
          <label for="email" class="sr-only">Search</label>
          <input
            type="email"
            name="email"
            id="email"
            class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            placeholder="Search Requests"
          />
        </form>
      </div>
      <div class="mt-10">
        <h3 class="text-sm font-medium text-gray-500">Active Data Requests</h3>
        <ul role="list" class="mt-4 divide-y divide-gray-200 border-b border-t border-gray-200">
          <li class="flex items-center justify-between space-x-3 py-4">
            <div class="flex min-w-0 flex-1 items-center space-x-3">
              <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-medium text-gray-900">Request Name</p>
                <p class="truncate text-sm font-medium text-gray-500">Project Name</p>
              </div>
            </div>
            <div class="flex-shrink-0">
              <button
                type="button"
                class="inline-flex items-center gap-x-1.5 text-sm font-semibold leading-6 text-gray-900"
              >
                <svg
                  class="h-5 w-5 text-gray-400"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                </svg>
                Upload
              </button>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "uploads") |> stream(:requests, []),
     layout: {IngestWeb.Layouts, :dashboard}}
  end
end
