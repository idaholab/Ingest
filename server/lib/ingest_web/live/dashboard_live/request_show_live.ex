defmodule IngestWeb.RequestShowLive do
  import Ecto.Query
  alias Ingest.Requests.RequestMembers
  alias Ingest.Requests
  alias Ingest.Repo
  alias Ingest.Projects
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div
        :if={
          @request.destinations == [] || @request.templates == [] ||
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
          <span>
            <h1 class="text-2xl">
              <%= @request.name %> for <%= @request.project.name %>
              <span class="text-sm">
                <sup><a href={~p"/dashboard/requests/#{@request.id}/edit"}>Edit</a></sup>
              </span>
            </h1>
          </span>
          <p><%= @request.description %></p>
          <!-- PUBLIC/PRIVATE -->
          <div class="mt-20">
            <label id="listbox-label" class="sr-only">Change published status</label>
            <div class="relative">
              <div class="inline-flex divide-x divide-white-700 rounded-md shadow-sm">
                <div class={
                  if @request.status == :published do
                    "inline-flex items-center gap-x-1.5 rounded-l-md bg-green-600 px-3 py-2 text-white shadow-sm"
                  else
                    "inline-flex items-center gap-x-1.5 rounded-l-md bg-indigo-600 px-3 py-2 text-white shadow-sm"
                  end
                }>
                  <svg
                    class="-ml-0.5 h-5 w-5"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <p :if={@request.status == :draft} class="text-sm font-semibold">Draft</p>
                  <p :if={@request.status == :published} class="text-sm font-semibold">Published</p>
                </div>
                <button
                  :if={@request.destinations != [] && @request.templates != []}
                  phx-click={JS.toggle(to: "#publish_dropdown", in: "opacity-100", out: "opacity-0")}
                  type="button"
                  class={
                    if @request.status == :published do
                      "inline-flex items-center rounded-l-none rounded-r-md bg-green-600 p-2 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-600 focus:ring-offset-2 focus:ring-offset-gray-50"
                    else
                      "inline-flex items-center rounded-l-none rounded-r-md bg-indigo-600 p-2 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 focus:ring-offset-gray-50"
                    end
                  }
                  aria-haspopup="listbox"
                  aria-expanded="true"
                  aria-labelledby="listbox-label"
                >
                  <span class="sr-only">Change published status</span>
                  <svg
                    class="h-5 w-5 text-white"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </button>

                <button
                  :if={@request.destinations == [] || @request.templates == []}
                  disable
                  type="button"
                  class="inline-flex items-center rounded-l-none rounded-r-md bg-indigo-600 cursor-not-allowed p-2 hover:bg-indigo-700 "
                  aria-haspopup="listbox"
                  aria-expanded="true"
                  aria-labelledby="listbox-label"
                >
                  <span class="sr-only">Change published status</span>
                  <svg
                    class="h-5 w-5 text-white"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </button>
              </div>

              <ul
                phx-click-away={
                  JS.toggle(to: "#publish_dropdown", in: "opacity-100", out: "opacity-0")
                }
                id="publish_dropdown"
                class=" hidden absolute left-0 z-10 mt-2 w-72 origin-top-right divide-y divide-gray-200 overflow-hidden rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                tabindex="-1"
                role="listbox"
                aria-labelledby="listbox-label"
                aria-activedescendant="listbox-option-0"
              >
                <li
                  class="text-gray-900 cursor-default select-none p-4 text-sm hover:text-white hover:bg-indigo-600  "
                  id="listbox-option-0"
                  role="option"
                  phx-click="set_draft"
                >
                  <div class="flex flex-col cursor-pointer">
                    <div class="flex justify-between">
                      <!-- Selected: "font-semibold", Not Selected: "font-normal" -->
                      <p class="font-normal">Draft</p>

                      <span :if={@request.status == :draft}>
                        <svg
                          class="h-5 w-5"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          aria-hidden="true"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                            clip-rule="evenodd"
                          />
                        </svg>
                      </span>
                    </div>
                    <p class="mt-2">
                      Disable uploads for this request.
                    </p>
                  </div>
                </li>
                <li
                  class="text-gray-900 cursor-default select-none p-4 text-sm hover:text-white hover:bg-indigo-600  "
                  id="listbox-option-0"
                  role="option"
                  phx-click="set_published"
                >
                  <div class="flex flex-col cursor-pointer">
                    <div class="flex justify-between">
                      <!-- Selected: "font-semibold", Not Selected: "font-normal" -->
                      <p class="font-normal">Published</p>

                      <span :if={@request.status == :published}>
                        <svg
                          class="h-5 w-5"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                          aria-hidden="true"
                        >
                          <path
                            fill-rule="evenodd"
                            d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                            clip-rule="evenodd"
                          />
                        </svg>
                      </span>
                    </div>
                    <p class="mt-2">
                      Enable this request for data uploads.
                    </p>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
      <div class="grid grid-cols-2 mt-15">
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

          <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
            <table class="w-[40rem] mt-11 sm:w-full">
              <thead class="text-sm text-left leading-6 text-zinc-500">
                <tr>
                  <th class="p-0 pr-6 pb-4 font-normal">Name</th>
                  <th class="relative p-0 pb-4"><span class="sr-only">Actions</span></th>
                </tr>
              </thead>
              <tbody
                id="requests"
                class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
              >
                <tr :for={template <- @project_templates}>
                  <td class="p-0 pb-4 pr-6">
                    <div class="py-4 pr-6 text-sm font-semibold leading-6 text-gray-900">
                      <%= template.name %>
                    </div>
                  </td>
                  <td class="relative w-14 p-0">
                    <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                      <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                        Default
                      </span>
                    </div>
                  </td>
                </tr>
                <tr :for={template <- @request_templates}>
                  <td class="p-0 pb-4 pr-6">
                    <div class="py-4 pr-6 text-sm font-semibold leading-6 text-gray-900">
                      <%= template.name %>
                    </div>
                  </td>
                  <td class="relative w-14 p-0">
                    <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                      <.link
                        data-confirm="Are you sure?"
                        phx-click="remove_template"
                        phx-value-id={template.id}
                        class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 cursor-pointer"
                      >
                        Remove
                      </.link>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="relative flex justify-center mt-10">
            <.link patch={~p"/dashboard/requests/#{@request.id}/search/templates"}>
              <button
                type="button"
                class="inline-flex items-center rounded-md bg-gray-600 hover:text-white text-black px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-gray-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                <.icon name="hero-plus" /> Add Template
              </button>
            </.link>
          </div>
        </div>
        <!-- STATUS -->
        <div class="ml-4">
          <div class="relative ">
            <div class="absolute inset-0 flex items-center" aria-hidden="true"></div>
          </div>
          <div class="relative flex justify-center">
            <.icon
              :if={@request.status == :published}
              name="hero-check-circle"
              class="text-green-600 w-40 h-40"
            />
            <.icon
              :if={@request.status == :draft}
              name="hero-exclamation-circle"
              class="text-gray-600 w-40 h-40"
            />
          </div>

          <div class="relative flex justify-center">
            <p :if={@request.status == :published}>Request Published and Acting Normally</p>
            <p :if={@request.status == :draft}>Request Not Published</p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2">
        <!-- DESTINATIONS -->
        <div class=" border-r-2 pr-5">
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
            <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
              <table class="w-[40rem] mt-11 sm:w-full">
                <thead class="text-sm text-left leading-6 text-zinc-500">
                  <tr>
                    <th class="p-0 pr-6 pb-4 font-normal">Name</th>
                    <th class="relative p-0 pb-4"><span class="sr-only">Actions</span></th>
                  </tr>
                </thead>
                <tbody
                  id="requests"
                  class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
                >
                  <tr :for={destination <- @project_destinations}>
                    <td class="p-0 pb-4 pr-6">
                      <div class="flex min-w-0 gap-x-4 mt-4">
                        <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-500 ">
                          <span class="font-medium leading-none text-white">
                            <span :if={destination.type == :s3}>S3</span>
                            <span :if={destination.type == :azure}>AZ</span>
                            <span :if={destination.type == :internal}>I</span>
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
                    </td>
                    <td class="relative w-14 p-0">
                      <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                        <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                          Active
                        </span>
                        <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                          Default
                        </span>
                      </div>
                    </td>
                  </tr>
                  <tr :for={destination <- @request_destinations}>
                    <td class="p-0 pb-4 pr-6">
                      <div class="flex min-w-0 gap-x-4 mt-4">
                        <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-500">
                          <span class="font-medium leading-none text-white">
                            <span :if={destination.type == :s3}>S3</span>
                            <span :if={destination.type == :azure}>AZ</span>
                            <span :if={destination.type == :internal}>I</span>
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
                    </td>
                    <td class="relative w-14 p-0">
                      <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
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
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="relative flex justify-center mt-10">
              <.link patch={~p"/dashboard/requests/#{@request.id}/search/destinations"}>
                <button
                  type="button"
                  class="inline-flex items-center rounded-md bg-gray-600 px-3 py-2 text-sm text-black hover:text-white font-semibold text-white shadow-sm hover:bg-gray-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  <.icon name="hero-plus" /> Add Destination
                </button>
              </.link>
            </div>
          </div>
        </div>

        <div class="mx-auto max-w-lg">
          <div class=" pt-4">
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
            <ul role="list" class="divide-y divide-gray-100">
              <%= for member <- @members do %>
                <li class="flex items-center justify-between gap-x-6 py-5">
                  <div class="flex min-w-0 gap-x-4">
                    <div class="min-w-0 flex-auto">
                      <p class="text-sm font-semibold leading-6 text-gray-900">
                        <%= member.email %>
                      </p>
                    </div>
                  </div>
                  <div>
                    <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                      Active
                    </span>

                    <span
                      data-confirm="Are you sure?"
                      phx-click="remove_member"
                      phx-value-email={member.email}
                      class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 cursor-pointer"
                    >
                      Remove
                    </span>
                  </div>
                </li>
              <% end %>
            </ul>
            <form action="#" class="mt-12 flex text-center">
              <label id="listbox-label" class="sr-only">Change visibility </label>
              <div class="relative pl-12">
                <div class="inline-flex divide-x divide-white-700 rounded-md shadow-sm">
                  <div class={
                    if @request.visibility == :public do
                      "inline-flex items-center gap-x-1.5 rounded-l-md bg-green-600 px-3 py-2 text-white shadow-sm"
                    else
                      "inline-flex items-center gap-x-1.5 rounded-l-md bg-indigo-600 px-3 py-2 text-white shadow-sm"
                    end
                  }>
                    <svg
                      class="-ml-0.5 h-5 w-5"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    <p :if={@request.visibility == :public} class="text-sm font-semibold">Public</p>
                    <p :if={@request.visibility == :internal} class="text-sm font-semibold">
                      Internal Only
                    </p>
                    <p :if={@request.visibility == :private} class="text-sm font-semibold">Private</p>
                  </div>
                  <button
                    phx-click={
                      JS.toggle(to: "#visibility_dropdown", in: "opacity-100", out: "opacity-0")
                    }
                    type="button"
                    class={
                      if @request.visibility == :public do
                        "inline-flex items-center rounded-l-none rounded-r-md bg-green-600 p-2 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-600 focus:ring-offset-2 focus:ring-offset-gray-50"
                      else
                        "inline-flex items-center rounded-l-none rounded-r-md bg-indigo-600 p-2 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 focus:ring-offset-gray-50"
                      end
                    }
                    aria-haspopup="listbox"
                    aria-expanded="true"
                    aria-labelledby="listbox-label"
                  >
                    <span class="sr-only">Change published status</span>
                    <svg
                      class="h-5 w-5 text-white"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </button>
                </div>

                <ul
                  phx-click-away={
                    JS.toggle(to: "#visibility_dropdown", in: "opacity-100", out: "opacity-0")
                  }
                  id="visibility_dropdown"
                  class=" hidden absolute left-0 z-10 mt-2 w-72 origin-top-right divide-y divide-gray-200 overflow-hidden rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                  tabindex="-1"
                  role="listbox"
                  aria-labelledby="listbox-label"
                  aria-activedescendant="listbox-option-0"
                >
                  <li
                    class="text-gray-900 cursor-default select-none p-4 text-sm hover:text-white hover:bg-indigo-600  "
                    id="listbox-option-0"
                    role="option"
                    phx-click="set_public"
                  >
                    <div class="flex flex-col cursor-pointer">
                      <div class="flex justify-between">
                        <!-- Selected: "font-semibold", Not Selected: "font-normal" -->
                        <p class="font-normal">Public</p>

                        <span :if={@request.visibility == :public}>
                          <svg
                            class="h-5 w-5"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                              clip-rule="evenodd"
                            />
                          </svg>
                        </span>
                      </div>
                      <p class="mt-2">
                        Allow all users with approved email domains to upload data. Visible in searches.
                      </p>
                    </div>
                  </li>
                  <li
                    class="text-gray-900 cursor-default select-none p-4 text-sm hover:text-white hover:bg-indigo-600  "
                    id="listbox-option-0"
                    role="option"
                    phx-click="set_internal"
                  >
                    <div class="flex flex-col cursor-pointer">
                      <div class="flex justify-between">
                        <!-- Selected: "font-semibold", Not Selected: "font-normal" -->
                        <p class="font-normal">Internal Only</p>

                        <span :if={@request.visibility == :internal}>
                          <svg
                            class="h-5 w-5"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                              clip-rule="evenodd"
                            />
                          </svg>
                        </span>
                      </div>
                      <p class="mt-2">
                        Allow all users with approved email domains to upload data. Not in searches.
                      </p>
                    </div>
                  </li>
                  <li
                    class="text-gray-900 cursor-default select-none p-4 text-sm hover:text-white hover:bg-indigo-600  "
                    id="listbox-option-0"
                    role="option"
                    phx-click="set_private"
                  >
                    <div class="flex flex-col cursor-pointer">
                      <div class="flex justify-between">
                        <!-- Selected: "font-semibold", Not Selected: "font-normal" -->
                        <p class="font-normal">Private</p>

                        <span :if={@request.visibility == :private}>
                          <svg
                            class="h-5 w-5"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                            aria-hidden="true"
                          >
                            <path
                              fill-rule="evenodd"
                              d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                              clip-rule="evenodd"
                            />
                          </svg>
                        </span>
                      </div>
                      <p class="mt-2">
                        Allow only invited users to upload data.
                      </p>
                    </div>
                  </li>
                </ul>
              </div>
              <div>
                <.link patch={~p"/dashboard/requests/#{@request.id}/invite"}>
                  <button class="ml-4 flex-shrink-0 rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
                    Send Invite
                  </button>
                </.link>
              </div>
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
          project_templates={@project_templates}
          project_destinations={@project_destinations}
        />
      </.modal>

      <.modal
        :if={@live_action in [:edit]}
        id="request_modal"
        show
        on_cancel={JS.patch(~p"/dashboard/requests/#{@request.id}")}
      >
        <.live_component
          live_action={@live_action}
          request_form={@request_form}
          request={@request}
          module={IngestWeb.LiveComponents.RequestForm}
          id="request-modal-component"
          current_user={@current_user}
          patch={~p"/dashboard/requests/#{@request.id}"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:invite]}
        id="invite_modal"
        show
        on_cancel={JS.patch(~p"/dashboard/requests/#{@request.id}")}
      >
        <.live_component
          module={IngestWeb.LiveComponents.InviteForm}
          id="invite-modal-component"
          request={@request}
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
    changeset = Requests.change_request(request)

    project = Projects.get_project!(request.project_id)

    # set back to draft if there are not enough parts - not a catch all, but works most of the time if they remove something
    if request.templates == [] || request.destinations == [] do
      Requests.update_request(request, %{status: :draft})
    end

    members =
      RequestMembers
      |> where(request_id: ^request.id)
      |> Repo.all()

    {:noreply,
     socket
     |> assign(:request_templates, request.templates)
     |> assign(:request_destinations, request.destinations)
     |> assign(:project_templates, project.templates)
     |> assign(:project_destinations, project.destinations)
     |> assign(:members, members)
     |> assign(:request, request)
     |> assign(:request_form, to_form(changeset))
     |> stream(:templates, request.templates)
     |> stream(:destinations, request.destinations)}
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
  def handle_event("remove_template", %{"id" => id}, socket) do
    template = Ingest.Requests.get_template!(id)
    {1, _} = Ingest.Requests.remove_template(socket.assigns.request, template)

    {:noreply,
     stream_delete(socket, :templates, template)
     |> push_patch(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end

  @impl true
  def handle_event("set_published", _params, socket) do
    {:ok, request} = Requests.update_request(socket.assigns.request, %{status: :published})

    {:noreply,
     socket
     |> assign(:request, Requests.get_request!(request.id))
     |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end

  @impl true
  def handle_event("set_draft", _params, socket) do
    {:ok, request} = Requests.update_request(socket.assigns.request, %{status: :draft})

    {:noreply,
     socket
     |> assign(:request, Requests.get_request!(request.id))
     |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end

  @impl true
  def handle_event("set_private", _params, socket) do
    {:ok, request} = Requests.update_request(socket.assigns.request, %{visibility: :private})

    {:noreply,
     socket
     |> assign(:request, Requests.get_request!(request.id))
     |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end

  @impl true
  def handle_event("set_internal", _params, socket) do
    {:ok, request} = Requests.update_request(socket.assigns.request, %{visibility: :internal})

    {:noreply,
     socket
     |> assign(:request, Requests.get_request!(request.id))
     |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end

  @impl true
  def handle_event("set_public", _params, socket) do
    {:ok, request} = Requests.update_request(socket.assigns.request, %{visibility: :public})

    {:noreply,
     socket
     |> assign(:request, Requests.get_request!(request.id))
     |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end

  def handle_event("remove_member", %{"email" => email}, socket) do
    Requests.delete_user(socket.assigns.request, email)

    {:noreply,
     socket
     |> assign(:request, Requests.get_request!(socket.assigns.request.id))
     |> put_flash(:info, "Member has been removed from this data request!")
     |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
  end
end
