defmodule IngestWeb.RequestShowLive do
  alias Ingest.Requests
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div
        :if={
          @request.projects == [] || @request.destinations == [] || @request.templates == [] ||
            @request.status != :published
        }
        class="lg:border-b lg:border-t lg:border-gray-200 mb-10 "
      >
        <nav class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 " aria-label="Progress">
          <ol
            role="list"
            class="overflow-hidden rounded-md lg:flex lg:rounded-none lg:border-l lg:border-r lg:border-gray-200"
          >
            <li class="relative overflow-hidden lg:flex-1">
              <div class="overflow-hidden border border-gray-200 rounded-t-md border-b-0 lg:border-0">
                <!-- Completed Step -->
                <span
                  class="absolute left-0 top-0 h-full w-1 bg-transparent group-hover:bg-gray-200 lg:bottom-0 lg:top-auto lg:h-1 lg:w-full"
                  aria-hidden="true"
                >
                </span>
                <span class="flex items-start px-6 py-5 text-sm font-medium">
                  <span class="flex-shrink-0">
                    <span
                      :if={@request.projects == []}
                      class="flex h-10 w-10 items-center justify-center rounded-full border-2 border-gray-300"
                    >
                      <span class="text-gray-500">X</span>
                    </span>

                    <span
                      :if={@request.projects != []}
                      class="flex h-10 w-10 items-center justify-center rounded-full bg-indigo-600"
                    >
                      <svg
                        class="h-6 w-6 text-white"
                        viewBox="0 0 24 24"
                        fill="currentColor"
                        aria-hidden="true"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M19.916 4.626a.75.75 0 01.208 1.04l-9 13.5a.75.75 0 01-1.154.114l-6-6a.75.75 0 011.06-1.06l5.353 5.353 8.493-12.739a.75.75 0 011.04-.208z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </span>
                  </span>
                  <span class="ml-4 mt-0.5 flex min-w-0 flex-col">
                    <span class="text-sm font-medium">Add Projects</span>
                    <span class="text-sm font-medium text-gray-500">
                      Determine what projects the data is for.
                    </span>
                  </span>
                </span>
              </div>
            </li>

            <li class="relative overflow-hidden lg:flex-1">
              <div class="overflow-hidden border border-gray-200 rounded-b-md border-t-0 lg:border-0">
                <!-- Upcoming Step -->
                <a href="#" class="group">
                  <span
                    class="absolute left-0 top-0 h-full w-1 bg-transparent group-hover:bg-gray-200 lg:bottom-0 lg:top-auto lg:h-1 lg:w-full"
                    aria-hidden="true"
                  >
                  </span>
                  <span class="flex items-start px-6 py-5 text-sm font-medium lg:pl-9">
                    <span class="flex-shrink-0">
                      <span
                        :if={@request.templates == []}
                        class="flex h-10 w-10 items-center justify-center rounded-full border-2 border-gray-300"
                      >
                        <span class="text-gray-500">X</span>
                      </span>

                      <span
                        :if={@request.templates != []}
                        class="flex h-10 w-10 items-center justify-center rounded-full bg-indigo-600"
                      >
                        <svg
                          class="h-6 w-6 text-white"
                          viewBox="0 0 24 24"
                          fill="currentColor"
                          aria-hidden="true"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M19.916 4.626a.75.75 0 01.208 1.04l-9 13.5a.75.75 0 01-1.154.114l-6-6a.75.75 0 011.06-1.06l5.353 5.353 8.493-12.739a.75.75 0 011.04-.208z"
                            clip-rule="evenodd"
                          />
                        </svg>
                      </span>
                    </span>
                    <span class="ml-4 mt-0.5 flex min-w-0 flex-col">
                      <span class="text-sm font-medium">Add Templates</span>
                      <span class="text-sm font-medium text-gray-500">
                        Determine what data should be collected.
                      </span>
                    </span>
                  </span>
                </a>
                <!-- Separator -->
                <div class="absolute inset-0 left-0 top-0 hidden w-3 lg:block" aria-hidden="true">
                  <svg
                    class="h-full w-full text-gray-300"
                    viewBox="0 0 12 82"
                    fill="none"
                    preserveAspectRatio="none"
                  >
                    <path
                      d="M0.5 0V31L10.5 41L0.5 51V82"
                      stroke="currentcolor"
                      vector-effect="non-scaling-stroke"
                    />
                  </svg>
                </div>
              </div>
            </li>

            <li class="relative overflow-hidden lg:flex-1">
              <div class="overflow-hidden border border-gray-200 rounded-b-md border-t-0 lg:border-0">
                <!-- Upcoming Step -->
                <a href="#" class="group">
                  <span
                    class="absolute left-0 top-0 h-full w-1 bg-transparent group-hover:bg-gray-200 lg:bottom-0 lg:top-auto lg:h-1 lg:w-full"
                    aria-hidden="true"
                  >
                  </span>
                  <span class="flex items-start px-6 py-5 text-sm font-medium lg:pl-9">
                    <span class="flex-shrink-0">
                      <span
                        :if={@request.destinations == []}
                        class="flex h-10 w-10 items-center justify-center rounded-full border-2 border-gray-300"
                      >
                        <span class="text-gray-500">X</span>
                      </span>

                      <span
                        :if={@request.destinations != []}
                        class="flex h-10 w-10 items-center justify-center rounded-full bg-indigo-600"
                      >
                        <svg
                          class="h-6 w-6 text-white"
                          viewBox="0 0 24 24"
                          fill="currentColor"
                          aria-hidden="true"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M19.916 4.626a.75.75 0 01.208 1.04l-9 13.5a.75.75 0 01-1.154.114l-6-6a.75.75 0 011.06-1.06l5.353 5.353 8.493-12.739a.75.75 0 011.04-.208z"
                            clip-rule="evenodd"
                          />
                        </svg>
                      </span>
                    </span>
                    <span class="ml-4 mt-0.5 flex min-w-0 flex-col">
                      <span class="text-sm font-medium">Add Destinations</span>
                      <span class="text-sm font-medium text-gray-500">
                        Determine where the data should end up.
                      </span>
                    </span>
                  </span>
                </a>
                <!-- Separator -->
                <div class="absolute inset-0 left-0 top-0 hidden w-3 lg:block" aria-hidden="true">
                  <svg
                    class="h-full w-full text-gray-300"
                    viewBox="0 0 12 82"
                    fill="none"
                    preserveAspectRatio="none"
                  >
                    <path
                      d="M0.5 0V31L10.5 41L0.5 51V82"
                      stroke="currentcolor"
                      vector-effect="non-scaling-stroke"
                    />
                  </svg>
                </div>
              </div>
            </li>

            <li class="relative overflow-hidden lg:flex-1">
              <div class="overflow-hidden border border-gray-200 rounded-b-md border-t-0 lg:border-0">
                <!-- Upcoming Step -->
                <span
                  class="absolute left-0 top-0 h-full w-1 bg-transparent group-hover:bg-gray-200 lg:bottom-0 lg:top-auto lg:h-1 lg:w-full"
                  aria-hidden="true"
                >
                </span>
                <span class="flex items-start px-6 py-5 text-sm font-medium lg:pl-9">
                  <span class="flex-shrink-0">
                    <span
                      :if={@request.status === :draft}
                      class="flex h-10 w-10 items-center justify-center rounded-full border-2 border-gray-300"
                    >
                      <span class="text-gray-500">X</span>
                    </span>

                    <span
                      :if={@request.status === :published}
                      class="flex h-10 w-10 items-center justify-center rounded-full bg-indigo-600"
                    >
                      <svg
                        class="h-6 w-6 text-white"
                        viewBox="0 0 24 24"
                        fill="currentColor"
                        aria-hidden="true"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M19.916 4.626a.75.75 0 01.208 1.04l-9 13.5a.75.75 0 01-1.154.114l-6-6a.75.75 0 011.06-1.06l5.353 5.353 8.493-12.739a.75.75 0 011.04-.208z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </span>
                  </span>
                  <span class="ml-4 mt-0.5 flex min-w-0 flex-col">
                    <span class="text-sm font-medium ">Publish</span>
                    <span class="text-sm font-medium text-gray-500">
                      Make your request available.
                    </span>
                  </span>
                </span>
                <!-- Separator -->
                <div class="absolute inset-0 left-0 top-0 hidden w-3 lg:block" aria-hidden="true">
                  <svg
                    class="h-full w-full text-gray-300"
                    viewBox="0 0 12 82"
                    fill="none"
                    preserveAspectRatio="none"
                  >
                    <path
                      d="M0.5 0V31L10.5 41L0.5 51V82"
                      stroke="currentcolor"
                      vector-effect="non-scaling-stroke"
                    />
                  </svg>
                </div>
              </div>
            </li>
          </ol>
        </nav>
      </div>

      <div class="grid grid-cols-2">
        <div>
          <h1 class="text-2xl"><%= @request.name %></h1>
          <p><%= @request.description %></p>
          <.form phx-change="toggle_public" id="public">
            <div class="grid grid-cols-1 gap-x-8 gap-y-10  pb-12 md:grid-cols-3">
              <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2 mt-10">
                <div class="sm:col-span-full">
                  <.label for="status-select">
                    Request Public
                  </.label>
                  <.input type="checkbox" name="value" value={@request.public} />
                </div>
              </div>
            </div>
          </.form>
        </div>

        <div class="mx-auto max-w-lg ">
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
              <button
                type="submit"
                class="ml-4 flex-shrink-0 rounded-md bg-gray-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                Copy Link
              </button>
            </form>
          </div>
        </div>
      </div>
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
                Remove
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
                Remove
              </.link>
            </:action>
          </.table>

          <div class="relative flex justify-center mt-10">
            <.link patch={~p"/dashboard/requests/#{@request.id}/search/templates"}>
              <button
                type="button"
                class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                <.icon name="hero-plus" /> Add Template
              </button>
            </.link>
          </div>
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

            <div class="relative flex justify-center mt-10">
              <.link patch={~p"/dashboard/requests/#{@request.id}/search/destinations"}>
                <button
                  type="button"
                  class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  <.icon name="hero-plus" /> Add Destination
                </button>
              </.link>
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

    {:noreply,
     stream_delete(socket, :destinations, destination)
     |> push_patch(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end

  @impl true
  def handle_event("remove_project", %{"id" => id}, socket) do
    project = Ingest.Projects.get_project!(id)
    {1, _} = Ingest.Requests.remove_project(socket.assigns.request, project)

    {:noreply,
     stream_delete(socket, :projects, project)
     |> push_patch(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end

  @impl true
  def handle_event("remove_template", %{"id" => id}, socket) do
    template = Ingest.Requests.get_template!(id)
    {1, _} = Ingest.Requests.remove_template(socket.assigns.request, template)

    {:noreply,
     stream_delete(socket, :templates, template)
     |> push_patch(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end
end
