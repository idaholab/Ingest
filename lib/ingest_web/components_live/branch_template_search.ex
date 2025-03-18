defmodule IngestWeb.LiveComponents.BranchTemplateSearch do
  @moduledoc """
  RequestModal is the modal for creating/editing Data Requests. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="space-y-12">
        <form phx-change="search" phx-target={@myself} id="search">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-full">
                <.label for="status-select">
                  Branching Option Display Text
                </.label>
                <.input type="text" name="name" value={@name} />
              </div>

              <div class="sm:col-span-full">
                <.input
                  :if={!@name}
                  disabled
                  type="text"
                  name="value"
                  value=""
                  placeholder="Enter display text first"
                />
                <.input
                  :if={@name}
                  type="text"
                  name="value"
                  value=""
                  placeholder="Start typing to search templates"
                />
              </div>
            </div>
          </div>
        </form>
      </div>

      <div>
        <ul :if={@results} role="list" class=" divide-gray-100">
          <div :if={@results && @results == []}>
            No Results....
          </div>

          <%= for result <- @results do %>
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">
                    {result.name}
                  </p>
                </div>
              </div>
              <div>
                <span
                  phx-click="add"
                  phx-value-id={result.id}
                  phx-value-name={@name}
                  phx-target={@myself}
                  class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/10 cursor-pointer"
                >
                  Choose
                </span>
              </div>
            </li>
          <% end %>
        </ul>
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
     |> assign(:name, nil)
     |> assign(:results, nil)
     |> assign(assigns)}
  end

  @impl true
  def handle_event("search", %{"value" => value, "name" => name}, socket) do
    {:noreply,
     socket
     |> assign(:name, name)
     |> assign(
       :results,
       Ingest.Requests.search_own_templates(value, socket.assigns.current_user)
     )}
  end

  @impl true
  def handle_event("search", %{"name" => name}, socket) do
    {:noreply,
     socket
     |> assign(:name, name)}
  end

  @impl true
  def handle_event("add", %{"id" => id}, socket) do
    notify_parent(
      {:branch_added, %{name: socket.assigns.name, template: Ingest.Requests.get_template!(id)}}
    )

    {:noreply, socket |> push_patch(to: socket.assigns.patch)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
