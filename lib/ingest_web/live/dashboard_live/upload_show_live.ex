defmodule IngestWeb.UploadShowLive do
  require Logger
  alias Ingest.Requests
  alias Ingest.Uploads
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-base font-semibold leading-6 text-gray-900">{@request.name}</h1>
          <p class="mt-2 text-sm text-gray-700">
            {@request.description}
          </p>
        </div>
      </div>
      <div :if={Application.get_env(:ingest, :show_classifications)} class="flex justify-center pb-5">
        <div>
          <p>
            The destination for your uploads is cleared to hold the following classifications of data
          </p>
          <div>
            <span
              :if={@classifications_allowed == [] || !@classifications_allowed}
              class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10"
            >
              UUR - Unclassified Unlimited Release
            </span>
            <span
              :for={classification <- @classifications_allowed}
              class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 mx-2"
            >
              {Atom.to_string(classification) |> String.upcase()}
            </span>
          </div>
        </div>
      </div>
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
                      {entry.client_name}
                    </h3>
                  </div>
                  <progress value={entry.progress} max="100">{entry.progress}%</progress>
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
                <:col :let={{_id, upload}} label="File Name">{upload.filename}</:col>
                <:col :let={{_id, upload}} label="Upload Date">
                  {"#{upload.inserted_at.month}-#{upload.inserted_at.day}-#{upload.inserted_at.year}"}
                </:col>
                <:col :let={{_id, upload}} label="Size">{mb(upload.size)}mb</:col>
                <:col :let={{_id, upload}} label="Extension">{upload.ext}</:col>

                <:action :let={{_id, upload}}>
                  <div :if={!Ecto.assoc_loaded?(upload.metadatas) || upload.metadatas == []}>
                    <.link
                      navigate={~p"/dashboard/uploads/#{@request}/#{upload}"}
                      class="text-indigo-600 hover:text-indigo-900"
                    >
                      Input Supporting Data
                    </.link>
                  </div>
                  <div :if={upload.metadatas != [] && Ecto.assoc_loaded?(upload.metadatas)}>
                    <p class="text-green-900">
                      <.icon name="hero-check-circle" class="bg-green-900" /> Supporting Data Entered
                    </p>
                  </div>
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

    classifications_allowed =
      (request.destinations ++ request.project.destinations)
      |> Enum.map(fn d -> d.classifications_allowed end)
      |> List.flatten()
      |> Enum.uniq()

    if Requests.invited?(socket.assigns.current_user) do
      {:ok,
       socket
       |> Phoenix.LiveView.put_flash(:error, "Access denied!")
       |> Phoenix.LiveView.redirect(to: ~p"/dashboard")}
    else
      {:ok,
       socket
       |> assign(:request, request)
       |> assign(:classifications_allowed, classifications_allowed)
       |> allow_upload(:files,
         auto_upload: true,
         progress: &handle_progress/3,
         accept: :any,
         max_entries: 100,
         max_file_size: 1_000_000_000_000_000,
         chunk_size: 5_242_880,
         writer: fn _name, entry, _socket ->
           {Ingest.Uploaders.MultiDestinationWriter,
            filename: "#{entry.client_name}",
            user: socket.assigns.current_user,
            destinations: request.destinations ++ request.project.destinations,
            request: request}
         end
       )
       |> stream(:uploads, Uploads.recent_uploads_for_user(socket.assigns.current_user, request))
       |> assign(:section, "uploads"), layout: {IngestWeb.Layouts, :dashboard}}
    end
  end

  @impl true
  def handle_params(%{"id" => _id}, _uri, socket) do
    {:noreply, socket}
  end

  defp handle_progress(:files, entry, socket) do
    if entry.done? do
      # meta should have the information for the destination and the location of the file
      # in the destination. We need to extract the information from the meta and then
      # pass it back into the db to record where in the destination this file is
      meta =
        consume_uploaded_entry(socket, entry, fn %{} = meta ->
          {:ok, meta}
        end)

      {:ok, upload} =
        Uploads.create_upload(
          %{
            size: entry.client_size,
            filename: entry.client_name,
            ext: entry.client_type
          },
          socket.assigns.request,
          socket.assigns.current_user
        )

      # record the path the file ended up in each of the destinations
      {statuses, _paths} =
        Enum.map(meta.destinations, fn {destination, path} ->
          Uploads.create_upload_destination_path(%{path: path}, upload, destination)
        end)
        |> Enum.unzip()

      if Enum.member?(statuses, :error) do
        Logger.error("failed to create upload destination paths")
      end

      {:noreply,
       socket
       |> push_navigate(to: ~p"/dashboard/uploads/#{socket.assigns.request}")
       |> stream_insert(:uploads, upload)
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
