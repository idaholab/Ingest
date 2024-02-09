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
                  fn {id, upload} -> JS.navigate(~p"/dashboard/uploads/#{@request}/#{upload}") end
                }
              >
                <:col :let={{id, upload}} label="File Name"><%= upload.filename %></:col>
                <:col :let={{id, upload}} label="Size"><%= mb(upload.size) %>mb</:col>
                <:col :let={{id, upload}} label="Extension"><%= upload.ext %></:col>

                <:action :let={{id, upload}}>
                  <.link
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
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:section, "uploads")
     |> allow_upload(:files,
       auto_upload: true,
       progress: &handle_progress/3,
       accept: :any,
       max_entries: 100,
       max_file_size: 1_000_000_000_000_000,
       chunk_size: 5_242_880
     ), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply,
     socket
     |> assign(:request, Requests.get_request!(id))
     |> stream(:uploads, Uploads.recent_uploads_for_user(socket.assigns.current_user))}
  end

  defp handle_progress(:files, entry, socket) do
    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          dest = Path.join("uploads", Path.basename(entry.client_name))
          File.cp!(path, dest)
          {:ok, dest}
        end)

      {:ok, file} =
        Uploads.create_upload(
          %{
            filename: entry.client_name,
            ext: entry.client_type,
            size: entry.client_size
          },
          socket.assigns.request,
          socket.assigns.current_user
        )

      {:noreply,
       socket
       |> stream_insert(:uploads, file)
       |> put_flash(:info, "file #{uploaded_file} uploaded")}
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
