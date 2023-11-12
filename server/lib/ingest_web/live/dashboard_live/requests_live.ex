defmodule IngestWeb.RequestsLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div :if={!@requests || length(@requests) == 0} class="text-center">
      <.icon name="hero-folder-plus" class="mx-auto h-12 w-12 text-gray-400" />
      <h3 class="mt-2 text-sm font-semibold text-gray-900">No requests</h3>
      <p class="mt-1 text-sm text-gray-500">Get started by creating a new request.</p>
      <.live_component module={IngestWeb.LiveComponents.RequestModal} id="request_modal_component" />
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "requests") |> assign(:requests, []),
     layout: {IngestWeb.Layouts, :dashboard}}
  end
end
