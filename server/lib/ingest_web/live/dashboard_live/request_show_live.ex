defmodule IngestWeb.RequestShowLive do
  alias Ingest.Requests
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <nav aria-label="Progress" class="mb-10">
        <ol role="list" class="space-y-4 md:flex md:space-x-8 md:space-y-0">
          <li class="md:flex-1">
            <!-- Completed Step -->
            <a
              href="#"
              class="group flex flex-col border-l-4 border-indigo-600 py-2 pl-4 hover:border-indigo-800 md:border-l-0 md:border-t-4 md:pb-0 md:pl-0 md:pt-4"
            >
              <span class="text-sm font-medium text-indigo-600 group-hover:text-indigo-800">
                Step 1
              </span>
              <span class="text-sm font-medium">Add Projects</span>
            </a>
          </li>
          <li class="md:flex-1">
            <!-- Current Step -->
            <a
              href="#"
              class="group flex flex-col border-l-4 border-gray-200 py-2 pl-4 hover:border-gray-300 md:border-l-0 md:border-t-4 md:pb-0 md:pl-0 md:pt-4"
              aria-current="step"
            >
              <span class="text-sm font-medium text-gray-500 group-hover:text-gray-700">Step 2</span>
              <span class="text-sm font-medium">Add Data Templates</span>
            </a>
          </li>
          <li class="md:flex-1">
            <!-- Upcoming Step -->
            <a
              href="#"
              class="group flex flex-col border-l-4 border-gray-200 py-2 pl-4 hover:border-gray-300 md:border-l-0 md:border-t-4 md:pb-0 md:pl-0 md:pt-4"
            >
              <span class="text-sm font-medium text-gray-500 group-hover:text-gray-700">Step 3</span>
              <span class="text-sm font-medium">Add Destinations</span>
            </a>
          </li>
          <li class="md:flex-1">
            <!-- Upcoming Step -->
            <a
              href="#"
              class="group flex flex-col border-l-4 border-gray-200 py-2 pl-4 hover:border-gray-300 md:border-l-0 md:border-t-4 md:pb-0 md:pl-0 md:pt-4"
            >
              <span class="text-sm font-medium text-gray-500 group-hover:text-gray-700">Step 4</span>
              <span class="text-sm font-medium">Change Status</span>
            </a>
          </li>
          <li class="md:flex-1">
            <!-- Upcoming Step -->
            <a
              href="#"
              class="group flex flex-col border-l-4 border-gray-200 py-2 pl-4 hover:border-gray-300 md:border-l-0 md:border-t-4 md:pb-0 md:pl-0 md:pt-4"
            >
              <span class="text-sm font-medium text-gray-500 group-hover:text-gray-700">Step 5</span>
              <span class="text-sm font-medium">Send Request</span>
            </a>
          </li>
        </ol>
      </nav>

      <h1 class="text-2xl"><%= @request.name %></h1>
      <p><%= @request.description %></p>
      <div class="grid grid-cols-2">
        <!-- PROJECTS -->
        <div class="pr-5 border-r-2">
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Projects
              </span>
            </div>
          </div>

          <.table id="projects" rows={@streams.projects}>
            <:col :let={{id, project}} label="Name"><%= project.name %></:col>

            <:action :let={{id, project}}>
              <.link
                data-confirm="Are you sure?"
                phx-click="remove_project"
                phx-value-id={project.id}
                class="text-red-600 hover:text-red-900"
              >
                Delete
              </.link>
            </:action>
          </.table>

          <div class="relative flex justify-center mt-10">
            <.link patch={~p"/dashboard/requests/#{@request.id}/search/projects"}>
              <button
                type="button"
                class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                <.icon name="hero-plus" /> Add Project
              </button>
            </.link>
          </div>
        </div>
        <!-- STATUS -->
        <div class="pr-5 pl-5 border-r-2">
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Status
              </span>
            </div>
          </div>
          <div class="relative flex justify-center">
            <.icon name="hero-check-circle" class="text-green-600 w-40 h-40" />
          </div>
          <div class="relative flex justify-center">
            <p class="text-xs">Click to change <.icon name="hero-arrow-up" /></p>
          </div>
          <div class="relative flex justify-center">
            <p>Request Published and Acting Normally</p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2">
        <div class="pr-5 border-r-2">
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Applied Data Templates
              </span>
            </div>
          </div>

          <.table id="requests" rows={@streams.templates}>
            <:col :let={{_id, template}} label="Name"><%= template.name %></:col>

            <:action :let={{id, template}}>
              <.link
                data-confirm="Are you sure?"
                phx-click="remove_template"
                phx-value-id={template.id}
                class="text-red-600 hover:text-red-900"
              >
                Delete
              </.link>
            </:action>
          </.table>
        </div>
        <!-- DESTINATIONS -->
        <div class="pl-5">
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Destinations
              </span>
            </div>
          </div>

          <div>
            <ul role="list" class="divide-y divide-gray-100">
              <%= for {id, destination} <- @streams.destinations do %>
                <li id={id} class="flex items-center justify-between gap-x-6 py-5">
                  <div class="flex min-w-0 gap-x-4">
                    <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-500">
                      <span class="font-medium leading-none text-white">
                        <span :if={destination.type == :s3}>S3</span>
                        <span :if={destination.type == :azure}>AZ</span>
                        <span :if={destination.type == :passive}>P</span>
                      </span>
                    </span>
                    <div class="min-w-0 flex-auto">
                      <p class="text-sm font-semibold leading-6 text-gray-900">
                        <%= destination.name %>
                      </p>
                      <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                        <%= destination.type %>
                      </p>
                    </div>
                  </div>
                  <div>
                    <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                      Active
                    </span>

                    <span
                      data-confirm="Are you sure?"
                      phx-click="remove_destination"
                      phx-value-id={destination.id}
                      phx-click={
                        JS.push("remove_destination", value: %{id: destination.id})
                        |> hide("##{destination.id}")
                      }
                      class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 cursor-pointer"
                    >
                      Remove
                    </span>
                  </div>
                </li>
              <% end %>
            </ul>

            <div class="mx-auto max-w-lg mt-44">
              <div>
                <div class="text-center">
                  <svg
                    class="mx-auto h-12 w-12 text-gray-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 48 48"
                    aria-hidden="true"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M34 40h10v-4a6 6 0 00-10.712-3.714M34 40H14m20 0v-4a9.971 9.971 0 00-.712-3.714M14 40H4v-4a6 6 0 0110.713-3.714M14 40v-4c0-1.313.253-2.566.713-3.714m0 0A10.003 10.003 0 0124 26c4.21 0 7.813 2.602 9.288 6.286M30 14a6 6 0 11-12 0 6 6 0 0112 0zm12 6a4 4 0 11-8 0 4 4 0 018 0zm-28 0a4 4 0 11-8 0 4 4 0 018 0z"
                    />
                  </svg>
                  <h2 class="mt-2 text-base font-semibold leading-6 text-gray-900">
                    Share Data Request
                  </h2>
                  <p class="mt-1 text-sm text-gray-500">
                    As the owner of this request, you can send direct invitations to upload data.
                  </p>
                </div>
                <form action="#" class="mt-6 flex">
                  <label for="email" class="sr-only">Email address</label>
                  <input
                    type="email"
                    name="email"
                    id="email"
                    class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                    placeholder="Enter an email"
                  />
                  <button
                    type="submit"
                    class="ml-4 flex-shrink-0 rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                  >
                    <!-- TODO: Complete email section -->
                    Send invite
                  </button>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
      <.modal
        :if={@live_action in [:search_projects, :search_destinations, :search_templates]}
        id="search_modal"
        show
        on_cancel={JS.patch(~p"/dashboard/requests/#{@request.id}")}
      >
        <.live_component
          live_action={@live_action}
          request={@request}
          module={IngestWeb.LiveComponents.SearchForm}
          id="search-modal-component"
          current_user={@current_user}
        />
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "requests"), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    request = Requests.get_request!(id)

    {:noreply,
     socket
     |> assign(:request, request)
     |> stream(:templates, request.templates)
     |> stream(:destinations, request.destinations)
     |> stream(:projects, request.projects)}
  end

  @impl true
  def handle_event("remove_destination", %{"id" => id}, socket) do
    destination = Ingest.Destinations.get_destination!(id)
    {1, _} = Ingest.Requests.remove_destination(socket.assigns.request, destination)

    {:noreply, stream_delete(socket, :destinations, destination)}
  end

  @impl true
  def handle_event("remove_project", %{"id" => id}, socket) do
    project = Ingest.Projects.get_project!(id)
    {1, _} = Ingest.Requests.remove_project(socket.assigns.request, project)

    {:noreply, stream_delete(socket, :projects, project)}
  end

  @impl true
  def handle_event("remove_template", %{"id" => id}, socket) do
    template = Ingest.Requests.get_template!(id)
    {1, _} = Ingest.Requests.remove_template(socket.assigns.request, template)

    {:noreply, stream_delete(socket, :templates, template)}
  end
end
