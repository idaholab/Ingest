defmodule IngestWeb.UploadShowLive do
  alias Ingest.Requests
  alias Ingest.Uploads
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form id="upload-form" phx-submit="save" phx-change="validate">
        <div class="mb-10" phx-drop-target={@uploads.files.ref}>
          <button
            phx-hook="UploadBox"
            data-file-ID={@uploads.files.ref}
            id="file_upload_button"
            type="button"
            class="relative block w-full rounded-lg border-2 border-dashed border-gray-300 p-12 text-center hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          >
            <.icon name="hero-document-arrow-up" class="mx-auto h-12 w-12 text-gray-400" />
            <span class="mt-2 block text-sm font-semibold text-gray-900">
              Click or Drag'n'Drop to Upload Files
            </span>
            <.live_file_input upload={@uploads.files} class="hidden" />
          </button>
        </div>
      </form>

      <div class="mb-10">
        <ul role="list" class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          <%= for entry <- @uploads.files.entries do %>
            <li class="col-span-1 divide-y divide-gray-200 rounded-lg bg-white shadow">
              <div class="flex w-full items-center justify-between space-x-6 p-6">
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  aria-label="cancel"
                >
                  &times;
                </button>
                <div class="flex-1 truncate">
                  <div class="flex items-center space-x-3">
                    <h3 class="truncate text-sm font-medium text-gray-900">
                      <%= entry.client_name %>
                    </h3>
                  </div>
                  <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
                </div>
                <.live_img_preview
                  entry={entry}
                  class="h-10 w-10 flex-shrink-0 rounded-full bg-gray-300"
                />
              </div>
            </li>
          <% end %>
        </ul>
      </div>

      <div class="px-4 sm:px-6 lg:px-8">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-gray-900">Recent Uploads</h1>
            <p class="mt-2 text-sm text-gray-700">
              A list of files you've recently uploaded.
            </p>
          </div>
        </div>
        <div class="flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8 pb-20 border-b mb-10">
              <.table
                id="requests"
                rows={@streams.uploads}
                row_click={
                  fn {_id, upload} -> JS.navigate(~p"/dashboard/uploads/#{@request}/#{upload}") end
                }
              >
                <:col :let={{_id, upload}} label="File Name"><%= upload.filename %></:col>
                <:col :let={{_id, upload}} label="Size"><%= mb(upload.size) %>mb</:col>
                <:col :let={{_id, upload}} label="Extension"><%= upload.ext %></:col>

                <:action :let={{_id, upload}}>
                  <.link
                    :if={upload.metadatas == []}
                    navigate={~p"/dashboard/uploads/#{@request}/#{upload}"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Input Metadata
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
  def mount(%{"id" => id}, _session, socket) do
    request = Requests.get_request!(id)

    if Requests.is_invited(socket.assigns.current_user) do
      {:ok,
       socket
       |> Phoenix.LiveView.put_flash(:error, "Access denied!")
       |> Phoenix.LiveView.redirect(to: ~p"/dashboard")}
    else
      {:ok,
       socket
       |> assign(:request, request)
       |> allow_upload(:files,
         auto_upload: true,
         progress: &handle_progress/3,
         accept: :any,
         max_entries: 100,
         max_file_size: 1_000_000_000_000_000,
         chunk_size: 4_000_000,
         chunk_timeout: 90_000_000,
         writer: fn _name, entry, _socket ->
           {Ingest.Uploaders.MultiDestinationWriter,
            filename:
              "#{request.project.name}/#{socket.assigns.current_user.name}/#{entry.client_name}",
            destinations: request.destinations}
         end
       )
       |> stream(:uploads, Uploads.recent_uploads_for_user(socket.assigns.current_user))
       |> assign(:section, "uploads"), layout: {IngestWeb.Layouts, :dashboard}}
    end
  end

  defp handle_progress(:files, entry, socket) do
    if entry.done? do
      {:noreply,
       socket
       |> put_flash(:info, "file  uploaded")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  defp mb(number) do
    if number do
      Float.floor(number / 1_000_000, 2)
    else
      0
    end
  end
end
