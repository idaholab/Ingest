defmodule IngestWeb.LiveComponents.SearchForm do
  @moduledoc """
  RequestModal is the modal for creating/editing Data Requests. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component
  alias Ingest.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="space-y-12">
        <.form phx-change="search" phx-target={@myself} id="search" phx-submit="save">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div :if={@live_action == :search_projects} class="sm:col-span-full">
                <.label for="status-select">
                  Search Projects
                </.label>
                <.input type="text" name="value" value="" />
              </div>
            </div>
          </div>
        </.form>
      </div>

      <div class="mt-6 flex items-center justify-end gap-x-6">
        <.button
          class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          phx-disable-with="Saving..."
        >
          Save
        </.button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("search", %{"value" => value}, socket) do
    search(socket, socket.assigns.live_action, value)
  end

  def search(socket, :search_projects, value) do
    dbg(Projects.search(value))
    {:noreply, socket}
  end
end
