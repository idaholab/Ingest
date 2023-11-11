defmodule IngestWeb.TemplateBuilderLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={!@templates || Enum.empty?(@templates)} class="text-center">
        <.icon name="hero-folder-plus" class="mx-auto h-12 w-12 text-gray-400" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No templates</h3>
        <p class="mt-1 text-sm text-gray-500">Get started by creating a new template.</p>
        <.link
          navigate={~p"/dashboard/templates/new"}
          type="button"
          class="mt-5 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          <.icon name="hero-plus" /> New Template
        </.link>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "templates") |> assign(:templates, []),
     layout: {IngestWeb.Layouts, :dashboard}}
  end
end
