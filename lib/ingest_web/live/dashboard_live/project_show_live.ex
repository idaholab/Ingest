defmodule IngestWeb.ProjectShowLive do
  alias Ingest.Projects
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-2">
      <div>
        <h1><%= @project.name %></h1>
      </div>
      <div>
        <div>
          <h3 class="text-base font-semibold leading-6 text-gray-900">Last 30 days</h3>
          <dl class="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-3">
            <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
              <dt class="truncate text-sm font-medium text-gray-500">Total Subscribers</dt>
              <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">71,897</dd>
            </div>
            <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
              <dt class="truncate text-sm font-medium text-gray-500">Avg. Open Rate</dt>
              <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">58.16%</dd>
            </div>
            <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
              <dt class="truncate text-sm font-medium text-gray-500">Avg. Click Rate</dt>
              <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">24.57%</dd>
            </div>
          </dl>
        </div>

        <div>
          <ul role="list" class="divide-y divide-gray-100">
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <img
                  class="h-12 w-12 flex-none rounded-full bg-gray-50"
                  src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt=""
                />
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">Leslie Alexander</p>
                  <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                    leslie.alexander@example.com
                  </p>
                </div>
              </div>
              <a
                href="#"
                class="rounded-full bg-white px-2.5 py-1 text-xs font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              >
                View
              </a>
            </li>
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <img
                  class="h-12 w-12 flex-none rounded-full bg-gray-50"
                  src="https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt=""
                />
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">Michael Foster</p>
                  <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                    michael.foster@example.com
                  </p>
                </div>
              </div>
              <a
                href="#"
                class="rounded-full bg-white px-2.5 py-1 text-xs font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              >
                View
              </a>
            </li>
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <img
                  class="h-12 w-12 flex-none rounded-full bg-gray-50"
                  src="https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt=""
                />
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">Dries Vincent</p>
                  <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                    dries.vincent@example.com
                  </p>
                </div>
              </div>
              <a
                href="#"
                class="rounded-full bg-white px-2.5 py-1 text-xs font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              >
                View
              </a>
            </li>
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <img
                  class="h-12 w-12 flex-none rounded-full bg-gray-50"
                  src="https://images.unsplash.com/photo-1517841905240-472988babdf9?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt=""
                />
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">Lindsay Walton</p>
                  <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                    lindsay.walton@example.com
                  </p>
                </div>
              </div>
              <a
                href="#"
                class="rounded-full bg-white px-2.5 py-1 text-xs font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              >
                View
              </a>
            </li>
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <img
                  class="h-12 w-12 flex-none rounded-full bg-gray-50"
                  src="https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt=""
                />
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">Courtney Henry</p>
                  <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                    courtney.henry@example.com
                  </p>
                </div>
              </div>
              <a
                href="#"
                class="rounded-full bg-white px-2.5 py-1 text-xs font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              >
                View
              </a>
            </li>
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <img
                  class="h-12 w-12 flex-none rounded-full bg-gray-50"
                  src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
                  alt=""
                />
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">Tom Cook</p>
                  <p class="mt-1 truncate text-xs leading-5 text-gray-500">tom.cook@example.com</p>
                </div>
              </div>
              <a
                href="#"
                class="rounded-full bg-white px-2.5 py-1 text-xs font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              >
                View
              </a>
            </li>
          </ul>
          <a
            href="#"
            class="flex w-full items-center justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-visible:outline-offset-0"
          >
            View all
          </a>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, session, socket) do
    {:ok, socket |> assign(:section, "projects") |> assign(:project, Projects.get_project!(id)),
     layout: {IngestWeb.Layouts, :dashboard}}
  end

  @imple true
  def handle_params(unsigned_params, uri, socket) do
    {:noreply, socket}
  end
end
