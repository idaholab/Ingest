defmodule IngestWeb.TasksLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={Ingest.Uploads.count_uploads_missing_metadata(@current_user) <= 0} class="text-center">
        <.icon name="hero-folder-plus" class="mx-auto h-12 w-12 text-gray-400" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No outstanding tasks</h3>
        <p class="mt-1 text-sm text-gray-500">You're all caught up!</p>
      </div>

      <div
        :if={Ingest.Uploads.count_uploads_missing_metadata(@current_user) > 0}
        class="px-4 sm:px-6 lg:px-8"
      >
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-gray-900">Metadata Tasks</h1>
            <p class="mt-2 text-sm text-gray-700">
              A list of all uploads you've made that require metadata entry.
            </p>
          </div>
        </div>
        <div class="mt-8 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <.table
                id="tasks"
                rows={@streams.tasks}
                row_click={
                  fn {_id, upload} ->
                    JS.navigate(~p"/dashboard/uploads/#{upload.request_id}/#{upload}")
                  end
                }
              >
                <:col :let={{_id, upload}} label="File Name"><%= upload.filename %></:col>
                <:col :let={{_id, upload}} label="Size"><%= mb(upload.size) %>mb</:col>
                <:col :let={{_id, upload}} label="Extension"><%= upload.ext %></:col>

                <:action :let={{_id, upload}}>
                  <.link
                    navigate={~p"/dashboard/uploads/#{upload.request_id}/#{upload}"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Input Supporting Data
                  </.link>
                </:action>
              </.table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:section, "tasks")
     |> stream(:tasks, Ingest.Uploads.uploads_missing_metadata(socket.assigns.current_user)),
     layout: {IngestWeb.Layouts, :dashboard}}
  end

  defp mb(number) do
    if number do
      Float.floor(number / 1_000_000, 2)
    else
      0
    end
  end
end
