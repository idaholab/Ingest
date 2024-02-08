defmodule IngestWeb.DashboardLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="divide-y divide-gray-200 overflow-hidden rounded-lg bg-gray-200 shadow sm:grid sm:grid-cols-2 sm:gap-px sm:divide-y-0">
      <div class="rounded-tl-lg rounded-tr-lg sm:rounded-tr-none group relative bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500">
        <div>
          <span class="inline-flex rounded-lg p-3 bg-teal-50 text-teal-700 ring-4 ring-white">
            <.icon name="hero-rectangle-group" class="h-6 w-6" />
          </span>
        </div>
        <div class="mt-8">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            <a href="/dashboard/projects" class="focus:outline-none">
              <!-- Extend touch target to entire panel -->
              <span class="absolute inset-0" aria-hidden="true"></span>
              Find or Create a Project
            </a>
          </h3>
          <p class="mt-2 text-sm text-gray-500">
            Projects are the root of all data requests. Find or create a project to begin working with data.
          </p>
        </div>
        <span
          class="pointer-events-none absolute right-6 top-6 text-gray-300 group-hover:text-gray-400"
          aria-hidden="true"
        >
          <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
            <path d="M20 4h1a1 1 0 00-1-1v1zm-1 12a1 1 0 102 0h-2zM8 3a1 1 0 000 2V3zM3.293 19.293a1 1 0 101.414 1.414l-1.414-1.414zM19 4v12h2V4h-2zm1-1H8v2h12V3zm-.707.293l-16 16 1.414 1.414 16-16-1.414-1.414z" />
          </svg>
        </span>
      </div>
      <div class="sm:rounded-tr-lg group relative bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500">
        <div>
          <span class="inline-flex rounded-lg p-3 bg-purple-50 text-purple-700 ring-4 ring-white">
            <.icon name="hero-circle-stack" class="h-6 w-6" />
          </span>
        </div>
        <div class="mt-8">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            <a href={~p"/dashboard/destinations"} class="focus:outline-none">
              <!-- Extend touch target to entire panel -->
              <span class="absolute inset-0" aria-hidden="true"></span>
              Create or Edit Destinations
            </a>
          </h3>
          <p class="mt-2 text-sm text-gray-500">
            Your data needs somewhere to go. Configure or edit already existing Data Destinations to make sure your data makes it to a good home.
          </p>
        </div>
        <span
          class="pointer-events-none absolute right-6 top-6 text-gray-300 group-hover:text-gray-400"
          aria-hidden="true"
        >
          <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
            <path d="M20 4h1a1 1 0 00-1-1v1zm-1 12a1 1 0 102 0h-2zM8 3a1 1 0 000 2V3zM3.293 19.293a1 1 0 101.414 1.414l-1.414-1.414zM19 4v12h2V4h-2zm1-1H8v2h12V3zm-.707.293l-16 16 1.414 1.414 16-16-1.414-1.414z" />
          </svg>
        </span>
      </div>
      <div class="group relative bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500">
        <div>
          <span class="inline-flex rounded-lg p-3 bg-sky-50 text-sky-700 ring-4 ring-white">
            <.icon name="hero-folder" class="h-6 w-6" />
          </span>
        </div>
        <div class="mt-8">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            <a href={~p"/dashboard/templates"} class="focus:outline-none">
              <!-- Extend touch target to entire panel -->
              <span class="absolute inset-0" aria-hidden="true"></span>
              Create a Metadata Template
            </a>
          </h3>
          <p class="mt-2 text-sm text-gray-500">
            Enforce the data that users are required to provide when uploading data. Templates allow you to enforce data standards across your project.
          </p>
        </div>
        <span
          class="pointer-events-none absolute right-6 top-6 text-gray-300 group-hover:text-gray-400"
          aria-hidden="true"
        >
          <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
            <path d="M20 4h1a1 1 0 00-1-1v1zm-1 12a1 1 0 102 0h-2zM8 3a1 1 0 000 2V3zM3.293 19.293a1 1 0 101.414 1.414l-1.414-1.414zM19 4v12h2V4h-2zm1-1H8v2h12V3zm-.707.293l-16 16 1.414 1.414 16-16-1.414-1.414z" />
          </svg>
        </span>
      </div>
      <div class="group relative bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500">
        <div>
          <span class="inline-flex rounded-lg p-3 bg-yellow-50 text-yellow-700 ring-4 ring-white">
            <.icon name="hero-arrow-up-on-square-stack" class="h-6 w-6" />
          </span>
        </div>
        <div class="mt-8">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            <a href={~p"/dashboard/uploads"} class="focus:outline-none">
              <!-- Extend touch target to entire panel -->
              <span class="absolute inset-0" aria-hidden="true"></span>
              Upload Data
            </a>
          </h3>
          <p class="mt-2 text-sm text-gray-500">
            Upload data to requests you've received, or search for active requests you have access to.
          </p>
        </div>
        <span
          class="pointer-events-none absolute right-6 top-6 text-gray-300 group-hover:text-gray-400"
          aria-hidden="true"
        >
          <svg class="h-6 w-6" fill="currentColor" viewBox="0 0 24 24">
            <path d="M20 4h1a1 1 0 00-1-1v1zm-1 12a1 1 0 102 0h-2zM8 3a1 1 0 000 2V3zM3.293 19.293a1 1 0 101.414 1.414l-1.414-1.414zM19 4v12h2V4h-2zm1-1H8v2h12V3zm-.707.293l-16 16 1.414 1.414 16-16-1.414-1.414z" />
          </svg>
        </span>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "dashboard"), layout: {IngestWeb.Layouts, :dashboard}}
  end
end
