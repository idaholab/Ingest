defmodule IngestWeb.RequestShowLive do
  import Ecto.Query
  alias Ingest.Uploads.UploadNotifier
  alias Ingest.Requests.RequestMembers
  alias Ingest.Requests
  alias Ingest.Repo
  alias Ingest.Projects
  alias Ingest.Uploads
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- start top banner -->
      <div class="flex justify-between ml-8 mr-8 mb-2">
        <div>
          <h1 class="text-2xl">
            {@request.name} for {@request.project.name}
            <span class="text-sm">
              <sup><a href={~p"/dashboard/requests/#{@request.id}/edit"}>Edit</a></sup>
            </span>
          </h1>
          <p>{@request.description}</p>
        </div>
        <div class="max-h-24 self-center">
          <ul role="list" class="divide-gray-100">
            <%= for member <- @members do %>
              <li class="flex items-center justify-between gap-x-6 py-5">
                <div class="flex min-w-0 gap-x-4">
                  <div class="min-w-0 flex-auto">
                    <p class="text-sm font-semibold leading-6 text-gray-900">
                      {member.email}
                    </p>
                  </div>
                </div>
                <div>
                  <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                    Active
                  </span>

                  <span
                    :if={
                      Bodyguard.permit?(
                        Ingest.Requests.Request,
                        :update_request,
                        @current_user,
                        @request
                      )
                    }
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
          <form action="#" class="flex text-center">
            <label id="listbox-label" class="sr-only">Change visibility </label>
            <div class="relative pl-12">
              <div
                :if={
                  Bodyguard.permit?(
                    Ingest.Requests.Request,
                    :update_request,
                    @current_user,
                    @request
                  )
                }
                class="inline-flex divide-x divide-white-700 rounded-md shadow-sm"
              >
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
                      Allow all users to upload data. Visible in searches.
                    </p>
                  </div>
                </li>

                <li
                  class="text-gray-900 cursor-default select-none p-4 text-sm hover:text-white hover:bg-indigo-600"
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
              id="copy_link_button"
              phx-hook="ClipboardCopy"
              data-body={url(~p"/dashboard/uploads/#{@request.id}")}
              class="ml-4 flex-shrink-0 rounded-md bg-gray-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Copy Link
            </button>
          </form>
        </div>
      </div>
      <!-- end top banner -->
      <div
        :if={
          (@request.destinations == [] && @project_destinations == []) ||
            (@request.templates == [] && @project_templates == []) ||
            @request.status != :published
        }
        class="lg:border-b lg:border-t lg:border-gray-200 mb-10"
      >
        <nav class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" aria-label="Progress">
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
                        :if={@request.templates == [] && @project_templates == []}
                        class="flex h-10 w-10 items-center justify-center rounded-full border-2 border-gray-300"
                      >
                        <span class="text-gray-500">X</span>
                      </span>

                      <span
                        :if={@request.templates != [] || @project_templates != []}
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
                      <span class="text-sm font-medium">Add Metadata Collection Forms</span>
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
                        :if={@request.destinations == [] && @project_destinations == []}
                        class="flex h-10 w-10 items-center justify-center rounded-full border-2 border-gray-300"
                      >
                        <span class="text-gray-500">X</span>
                      </span>

                      <span
                        :if={@request.destinations != [] || @project_destinations != []}
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
                      Make your request available by clicking the button below your request's title.
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
      <!-- Start Metadata Section -->
      <div class="grid grid-cols-1">
        <div>
          <!-- Start Metadata Header -->
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Applied Metadata Collection Forms
              </span>
            </div>
          </div>
          <!-- End Metadata Header -->
          <div class="px-30 overflow-y-auto sm:overflow-visible sm:px-5">
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
                      {template.name}
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
                      {template.name}
                    </div>
                  </td>
                  <td class="relative w-14 p-0">
                    <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                      <.link
                        :if={
                          Bodyguard.permit?(
                            Ingest.Requests.Request,
                            :update_request,
                            @current_user,
                            @request
                          )
                        }
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
            <.link
              :if={
                Bodyguard.permit?(Ingest.Requests.Request, :update_request, @current_user, @request)
              }
              patch={~p"/dashboard/requests/#{@request.id}/search/templates"}
            >
              <button
                type="button"
                class="inline-flex items-center rounded-md bg-gray-600 hover:text-white text-black px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-gray-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                <.icon name="hero-plus" /> Add Metadata Collection Form
              </button>
            </.link>
          </div>
        </div>
        <!-- STATUS -->
      </div>

      <!-- Start Name Section -->
      <div class="grid grid-cols-1">
        <div>
          <!-- Start Header -->
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                File Naming Convention
              </span>
            </div>
          </div>
          <!-- End Header -->

        </div>

      </div>
      <!-- End Name Section -->

      <div class="grid grid-cols-1">
        <!-- DESTINATIONS -->
        <div>
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Data Destinations
              </span>
            </div>
          </div>

          <div class="px-20">
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
                            {destination.name}
                          </p>
                          <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                            {destination.type}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td class="relative w-14 p-0">
                      <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                        <.link
                          :if={
                            Bodyguard.permit?(
                              Ingest.Destinations.Destination,
                              :update_destination,
                              @current_user,
                              destination
                            )
                          }
                          patch={~p"/dashboard/requests/#{@request}/destination/#{destination}"}
                          class="text-indigo-600 hover:text-indigo-900 px-5"
                        >
                          Configure
                        </.link>
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
                            <span :if={destination.type == :lakefs}>LF</span>
                            <span :if={destination.type == :internal}>I</span>
                          </span>
                        </span>
                        <div class="min-w-0 flex-auto">
                          <p class="text-sm font-semibold leading-6 text-gray-900">
                            {destination.name}
                          </p>
                          <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                            {destination.type}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td class="relative w-14 p-0">
                      <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                        <.link
                          :if={
                            Bodyguard.permit?(
                              Ingest.Destinations.Destination,
                              :update_destination,
                              @current_user,
                              destination
                            )
                          }
                          patch={~p"/dashboard/requests/#{@request}/destination/#{destination}"}
                          class="text-indigo-600 hover:text-indigo-900 px-5"
                        >
                          Configure
                        </.link>
                        <span
                          :if={
                            Bodyguard.permit?(
                              Ingest.Requests.Request,
                              :update_request,
                              @current_user,
                              @request
                            )
                          }
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

            <div class="relative flex justify-center">
              <.link
                :if={
                  Bodyguard.permit?(Ingest.Requests.Request, :update_request, @current_user, @request)
                }
                patch={~p"/dashboard/requests/#{@request.id}/search/destinations"}
              >
                <button
                  type="button"
                  class="inline-flex items-center rounded-md bg-gray-600 px-3 py-2 text-sm text-black hover:text-white font-semibold text-white shadow-sm hover:bg-gray-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  <.icon name="hero-plus" /> Add Data Destination
                </button>
              </.link>
            </div>
          </div>
        </div>
      </div>
      <.modal
        :if={@live_action == :destination_additional_config}
        id="config_destination_modal"
        show
        on_cancel={JS.patch(~p"/dashboard/requests/#{@request}")}
      >
        <.live_component
          destination={@destination}
          destination_member={@destination_member}
          request={@request}
          module={IngestWeb.LiveComponents.DestinationAddtionalConfigForm}
          id="share-destination-modal-component"
          current_user={@current_user}
          patch={JS.patch(~p"/dashboard/requests/#{@request}")}
        />
      </.modal>

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
          request_id={@request.id}
          current_user={@current_user}
          project_templates={@project_templates}
          project_destinations={@project_destinations}
          patch={"/dashboard/requests/#{@request.id}"}
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
      <!-- start publish -->
      <div class="pt-10">
        <div class="relative mt-10">
          <div class="absolute inset-0 flex items-center" aria-hidden="true">
            <div class="w-full border-t border-gray-300"></div>
          </div>
          <div class="relative flex justify-center">
            <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
              Publish Status
            </span>
          </div>
        </div>
        <div
          :if={Bodyguard.permit?(Ingest.Requests.Request, :update_request, @current_user, @request)}
          class="px-20 pt-10"
        >
          <fieldset aria-label="Privacy setting">
            <div class="-space-y-px rounded-md bg-white">
              <label
                :if={@request.status == :draft}
                class="z-10 border-indigo-200 bg-indigo-50 relative flex cursor-pointer rounded-tl-md rounded-tr-md border p-4 focus:outline-none"
              >
                <input
                  checked
                  type="radio"
                  class="mt-0.5 h-4 w-4 shrink-0 cursor-pointer border-gray-300 text-indigo-600 focus:ring-indigo-600 active:ring-2 active:ring-indigo-600 active:ring-offset-2"
                />
                <span class="ml-3 flex flex-col">
                  <span class="block text-sm text-indigo-900 font-medium">Draft</span>
                  <span class="block text-sm text-indigo-700">
                    Disable uploads and searching for this request.
                  </span>
                </span>
              </label>

              <label
                :if={@request.status != :draft}
                class="relative flex cursor-pointer rounded-tl-md rounded-tr-md border p-4 focus:outline-none"
              >
                <input
                  type="radio"
                  phx-click="set_draft"
                  class="mt-0.5 h-4 w-4 shrink-0 cursor-pointer border-gray-300 text-indigo-600 focus:ring-indigo-600 active:ring-2 active:ring-indigo-600 active:ring-offset-2"
                />
                <span class="ml-3 flex flex-col">
                  <span class="block text-sm font-medium">Draft</span>
                  <span class="block text-sm">
                    Disable uploads and searching for this request.
                  </span>
                </span>
              </label>
              <label
                :if={@request.status != :published}
                class={"relative flex #{ if (@request.templates != [] || @project_templates != []) &&
                  (@request.destinations != [] || @project_destinations != []) do "cursor-pointer" else "cursor-not-allowed" end} border p-4 focus:outline-none"}
              >
                <%= if (@request.templates != [] || @project_templates != []) &&
                (@request.destinations != [] || @project_destinations != []) do %>
                  <input
                    phx-click="set_published"
                    type="radio"
                    class="mt-0.5 h-4 w-4 shrink-0 cursor-pointer border-gray-300 text-indigo-600 focus:ring-indigo-600 active:ring-2 active:ring-indigo-600 active:ring-offset-2"
                  />
                <% else %>
                  <input
                    type="radio"
                    disabled
                    class="mt-0.5 h-4 w-4 shrink-0 cursor-pointer border-gray-300 text-indigo-600 focus:ring-indigo-600 active:ring-2 active:ring-indigo-600 active:ring-offset-2"
                  />
                <% end %>
                <span class="ml-3 flex flex-col">
                  <!-- Checked: "text-indigo-900", Not Checked: "text-gray-900" -->
                  <span class="block text-sm font-medium">Published</span>
                  <!-- Checked: "text-indigo-700", Not Checked: "text-gray-500" -->
                  <span class="block text-sm">
                    Enable uploads and the ability to search for this request by project.
                  </span>
                </span>
              </label>

              <label
                :if={@request.status == :published}
                class="relative flex cursor-pointer border p-4 focus:outline-none z-10 border-indigo-200 bg-indigo-50"
              >
                <input
                  type="radio"
                  checked
                  class="mt-0.5 h-4 w-4 shrink-0 cursor-pointer border-gray-300 text-indigo-600 focus:ring-indigo-600 active:ring-2 active:ring-indigo-600 active:ring-offset-2"
                />
                <span class="ml-3 flex flex-col">
                  <!-- Checked: "text-indigo-900", Not Checked: "text-gray-900" -->
                  <span class="block text-sm text-indigo-900 font-medium">Published</span>
                  <!-- Checked: "text-indigo-700", Not Checked: "text-gray-500" -->
                  <span class="block text-sm text-indigo-700">
                    Enable uploads and the ability to search for this request by project.
                  </span>
                </span>
              </label>
              <!-- Checked: "z-10 border-indigo-200 bg-indigo-50", Not Checked: "border-gray-200" -->
            </div>
          </fieldset>
        </div>
      </div>
      <!-- end publish -->
      <!-- start upload -->
      <div>
        <div class="mt-10">
          <div>
            <div class="relative">
              <div class="absolute inset-0 flex items-center" aria-hidden="true">
                <div class="w-full border-t border-gray-300"></div>
              </div>
              <div class="relative flex justify-center">
                <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                  Uploads
                </span>
              </div>
            </div>

            <div
              class="mt-8 flow-root px-20"
              phx-click-away={
                JS.hide(
                  to: "#filter_sort",
                  transition: {"ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
                )
              }
            >
              <div class="mx-auto ">
                <button
                  phx-click={
                    JS.toggle(
                      to: "#filter_sort",
                      in: {"ease-out duration-100", "opacity-0 scale-95", "opacity-100 scale-100"},
                      out: {"ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
                    )
                  }
                  class="hidden rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 sm:block cursor-pointer"
                >
                  Filter & Sort Results<.icon name="hero-adjustments-horizontal" />
                </button>

                <div class="relative flex-none ">
                  <div
                    id="filter_sort"
                    class="absolute hidden  z-10 mt-2 w-72 origin-top-right rounded-md bg-white py-2 shadow-lg ring-1 ring-gray-900/5 focus:outline-none"
                    role="menu"
                    aria-orientation="vertical"
                    aria-labelledby="options-menu-0-button"
                    tabindex="-1"
                  >
                    <.form for={@filter_form} id="filter_form" phx-change="reload">
                      <div class="sm:col-span-4">
                        <label for="sort-select" class="mx-2 text-sm">
                          Sort by:
                        </label>
                        <select
                          id="sort_select"
                          name="sort_select"
                          class="mt-2 block mx-2 w-64 rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
                        >
                          {Phoenix.HTML.Form.options_for_select(
                            [{"Date", :date}, {"Name", :name}, {"Status", :status}],
                            @filter_form[:sort].value
                          )}
                        </select>

                        <div class="mx-3 my-2">
                          <.input
                            type="checkbox"
                            field={@filter_form[:filter_completed]}
                            label="Show only incompleted uploads"
                          />
                        </div>
                      </div>
                    </.form>
                  </div>
                </div>
              </div>
              <ul
                class="mt-8 flow-root"
                id="uploads-table"
                phx-update="stream"
                phx-viewport-top={@page > 1 && "prev-page"}
                phx-viewport-bottom={!@end_of_timeline? && "next-page"}
                phx-page-loading
                class={[
                  if(@end_of_timeline?, do: "pb-10", else: "pb-[calc(200vh)]"),
                  if(@page == 1, do: "pt-10", else: "pt-[calc(200vh)]")
                ]}
                class="w-[40rem] mt-11 sm:w-full"
                role="list"
                class="divide-y divide-gray-100"
              >
                <li
                  :for={{id, upload} <- @streams.uploads}
                  id={id}
                  class="flex items-center justify-between gap-x-6 py-5"
                >
                  <div class="min-w-0">
                    <div class="flex items-start gap-x-3">
                      <p class="text-sm font-semibold leading-6 text-gray-900">
                        {upload.filename}
                      </p>
                      <p
                        :if={
                          upload.metadatas != [] &&
                            Enum.filter(upload.metadatas, fn m -> !m.submitted end) == []
                        }
                        class="mt-0.5 whitespace-nowrap rounded-md bg-green-50 px-1.5 py-0.5 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20"
                      >
                        Complete
                      </p>
                      <p
                        :if={
                          upload.metadatas == [] ||
                            Enum.filter(upload.metadatas, fn m -> !m.submitted end) != []
                        }
                        class="mt-0.5 whitespace-nowrap rounded-md bg-gray-50 px-1.5 py-0.5 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10"
                      >
                        Needs Supporting Data
                      </p>
                    </div>
                    <div class="mt-1 flex items-center gap-x-2 text-xs leading-5 text-gray-500">
                      <p class="whitespace-nowrap">
                        Uploaded on
                        <time datetime={upload.inserted_at}>
                          {NaiveDateTime.to_date(upload.inserted_at)}
                        </time>
                      </p>
                      <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 fill-current">
                        <circle cx="1" cy="1" r="1" />
                      </svg>
                      <p class="truncate">Uploaded by {upload.user.name}</p>
                    </div>
                  </div>
                  <div class="flex flex-none items-center gap-x-4">
                    <a
                      phx-click-away={
                        JS.hide(
                          to: "#upload-menu-#{upload.id}",
                          transition:
                            {"ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
                        )
                      }
                      phx-click={
                        JS.toggle(
                          to: "#upload-menu-#{upload.id}",
                          in:
                            {"ease-out duration-100", "opacity-0 scale-95", "opacity-100 scale-100"},
                          out: {"ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
                        )
                      }
                      class="hidden rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 sm:block cursor-pointer"
                    >
                      <.icon name="hero-pencil-square" />
                    </a>
                    <div class="relative flex-none ">
                      <div
                        id={"upload-menu-#{upload.id}"}
                        class="hidden absolute right-0 z-10 mt-2 w-64 origin-top-right rounded-md bg-white py-2 shadow-lg ring-1 ring-gray-900/5 focus:outline-none"
                        role="menu"
                        aria-orientation="vertical"
                        aria-labelledby="options-menu-0-button"
                        tabindex="-1"
                      >
                        <!-- Active: "bg-gray-50", Not Active: "" -->
                        <a
                          href={~p"/dashboard/uploads/#{@request.id}/#{upload.id}"}
                          class="block px-3 py-1 text-sm leading-6 text-gray-900 hover:bg-gray-50"
                          role="menuitem"
                          tabindex="-1"
                          id="options-menu-0-item-0"
                        >
                          Enter Supporting Data
                        </a>
                        <a
                          phx-click="notify_upload_owner"
                          phx-value-upload={upload.id}
                          class="block px-3 py-1 text-sm leading-6 text-gray-900 hover:bg-gray-50 cursor-pointer"
                          role="menuitem"
                          tabindex="-1"
                          id="options-menu-0-item-0"
                        >
                          Request Supporting Data
                        </a>
                        <a
                          class="disabled block px-3 py-1 text-sm leading-6 text-gray-900 bg-gray-50"
                          role="menuitem"
                          tabindex="-1"
                          id="options-menu-0-item-2"
                        >
                          Edit in Destination -
                          <p class="text-xs italic">coming soon</p>
                        </a>
                        <a
                          :if={
                            Bodyguard.permit?(
                              Ingest.Requests.Request,
                              :update_request,
                              @current_user,
                              @request
                            )
                          }
                          phx-click="delete_upload"
                          phx-value-upload={upload.id}
                          class="block px-3 py-1 text-sm leading-6 text-red-600 hover:bg-gray-50 cursor-pointer"
                          role="menuitem"
                          tabindex="-1"
                          id="options-menu-0-item-1"
                        >
                          Delete
                        </a>
                      </div>
                    </div>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
      <!-- end upload -->
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    request = Requests.get_request!(id)
    changeset = Requests.change_request(request)

    project = Projects.get_project!(request.project_id)

    # set back to draft if there are not enough parts - not a catch all, but works most of the time if they remove something
    if (request.templates == [] && project.templates == []) ||
         (request.destinations == [] && project.destinations == []) do
      Requests.update_request(request, %{status: :draft})
    end

    members =
      RequestMembers
      |> where(request_id: ^request.id)
      |> Repo.all()

    {:ok,
     socket
     |> assign(:section, "requests")
     |> stream(:uploads, [])
     |> assign(:destination, nil)
     |> assign(:destination_member, nil)
     |> assign(:filter_form, to_form(%{"sort" => "date", "filter_completed" => false}))
     |> assign(:request_templates, request.templates)
     |> assign(
       :request_destinations,
       request.destinations
       |> Enum.filter(fn d ->
         !Enum.member?(Enum.map(project.destinations, fn pd -> pd.id end), d.id)
       end)
     )
     |> assign(:project_templates, project.templates)
     |> assign(:project_destinations, project.destinations)
     |> assign(:members, members)
     |> assign(:request, request)
     |> assign(:request_form, to_form(changeset))
     |> stream(:templates, request.templates)
     |> assign(page: 1, per_page: 10)
     |> assign(filter_completed: false, sort: "date")
     |> paginate_uploads(1)
     |> stream(:destinations, request.destinations), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"destination_id" => destination, "id" => id} = _params, _uri, socket) do
    request = Requests.get_request!(id)
    project = Projects.get_project!(request.project_id)

    destination = Ingest.Destinations.get_destination!(destination)

    {:noreply,
     socket
     |> assign(:request, request)
     |> assign(:destination, destination)
     |> assign(:request_templates, request.templates)
     |> assign(
       :request_destinations,
       request.destinations
       |> Enum.filter(fn d ->
         !Enum.member?(Enum.map(project.destinations, fn pd -> pd.id end), d.id)
       end)
     )
     |> assign(:project_templates, project.templates)
     |> assign(:project_destinations, project.destinations)
     |> assign(
       :destination_member,
       Ingest.Destinations.list_destination_members(destination)
       |> Enum.find(fn member -> member.request_id == socket.assigns.request.id end)
     )}
  end

  @impl true
  def handle_params(%{"id" => id} = _params, _uri, socket) do
    request = Requests.get_request!(id)
    project = Projects.get_project!(request.project_id)

    {:noreply,
     socket
     |> assign(:request, request)
     |> assign(:request_templates, request.templates)
     |> assign(
       :request_destinations,
       request.destinations
       |> Enum.filter(fn d ->
         !Enum.member?(Enum.map(project.destinations, fn pd -> pd.id end), d.id)
       end)
     )
     |> assign(:project_templates, project.templates)
     |> assign(:project_destinations, project.destinations)}
  end

  @impl true
  def handle_event("remove_destination", %{"id" => id}, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         destination <- Ingest.Destinations.get_destination!(id) do
      {1, _} = Ingest.Requests.remove_destination(socket.assigns.request, destination)

      {:noreply,
       stream_delete(socket, :destinations, destination)
       |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  @impl true
  def handle_event("remove_template", %{"id" => id}, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         template <- Ingest.Requests.get_template!(id) do
      {1, _} = Ingest.Requests.remove_template(socket.assigns.request, template)

      {:noreply,
       stream_delete(socket, :templates, template)
       |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  @impl true
  def handle_event("set_published", _params, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         {:ok, request} <- Requests.update_request(socket.assigns.request, %{status: :published}) do
      {:noreply,
       socket
       |> assign(:request, Requests.get_request!(request.id))
       |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  @impl true
  def handle_event("set_draft", _params, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         {:ok, request} <- Requests.update_request(socket.assigns.request, %{status: :draft}) do
      {:noreply,
       socket
       |> assign(:request, Requests.get_request!(request.id))
       |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  @impl true
  def handle_event("set_private", _params, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         {:ok, request} <-
           Requests.update_request(socket.assigns.request, %{visibility: :private}) do
      {:noreply,
       socket
       |> assign(:request, Requests.get_request!(request.id))
       |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  @impl true
  def handle_event("set_internal", _params, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         {:ok, request} <-
           Requests.update_request(socket.assigns.request, %{visibility: :internal}) do
      {:noreply,
       socket
       |> assign(:request, Requests.get_request!(request.id))
       |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  @impl true
  def handle_event("set_public", _params, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         {:ok, request} <-
           Requests.update_request(socket.assigns.request, %{visibility: :public}) do
      {:noreply,
       socket
       |> assign(:request, Requests.get_request!(request.id))
       |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  def handle_event("remove_member", %{"email" => email}, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         :ok <- Requests.delete_user(socket.assigns.request, email) do
      {:noreply,
       socket
       |> assign(:request, Requests.get_request!(socket.assigns.request.id))
       |> put_flash(:info, "Member has been removed from this data request!")
       |> push_navigate(to: "/dashboard/requests/#{socket.assigns.request.id}")}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  @impl true
  def handle_event("notify_upload_owner", %{"upload" => upload_id}, socket) do
    upload = Uploads.get_upload!(upload_id)

    with {:ok, _notification} <-
           UploadNotifier.notify_upload_metadata(
             :notification,
             upload.user,
             upload,
             upload.request,
             IngestWeb.Endpoint.url()
           ),
         {:ok, _notification} <-
           UploadNotifier.notify_upload_metadata(
             :email,
             upload.user.email,
             upload,
             upload.request,
             IngestWeb.Endpoint.url()
           ) do
      {:noreply, socket |> put_flash(:info, "Successfully notified the upload's owner.")}
    else
      {:error, message} ->
        {:noreply, socket |> put_flash(:error, "Unable to notify upload owner #{message}")}
    end
  end

  @impl true
  def handle_event("delete_upload", %{"upload" => upload_id}, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.Request,
             :update_request,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         {:ok, upload} <- Uploads.delete_upload(Uploads.get_upload!(upload_id)) do
      {:noreply,
       socket
       |> put_flash(:info, "Successfully deleted upload")
       |> stream_delete(:uploads, upload)}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end

  @impl true
  def handle_event("next-page", _, socket) do
    {:noreply, paginate_uploads(socket, socket.assigns.page + 1)}
  end

  @impl true
  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate_uploads(socket, 1)}
  end

  @impl true
  def handle_event("prev-page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate_uploads(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "reload",
        %{"filter_completed" => filter_completed, "sort_select" => sort_select},
        socket
      ) do
    {:noreply,
     socket
     |> assign(filter_completed: filter_completed == "true", sort: sort_select)
     |> paginate_uploads(1, true)}
  end

  defp paginate_uploads(socket, new_page, hard_reset \\ false) when new_page >= 1 do
    %{per_page: per_page, page: cur_page} = socket.assigns

    uploads =
      Uploads.uploads_for_request(socket.assigns.request, (new_page - 1) * per_page, per_page,
        filter_completed: socket.assigns.filter_completed,
        sort: socket.assigns.sort
      )

    {uploads, at, limit} =
      if new_page >= cur_page do
        {uploads, -1, per_page * 3 * -1}
      else
        {Enum.reverse(uploads), 0, per_page * 3}
      end

    case uploads do
      [] ->
        assign(socket, end_of_timeline?: at == -1)

      [_ | _] = uploads ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(:page, new_page)
        |> stream(:uploads, uploads, at: at, limit: limit, reset: hard_reset)
    end
  end
end
