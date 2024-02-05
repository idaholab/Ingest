defmodule IngestWeb.UploadShowLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <form id="upload-form" phx-submit="save" phx-change="validate">
      <div class="mb-10" phx-drop-target={@uploads.files.ref}>
        <button
          phx-hook="UploadBox"
          data-file-ID={@uploads.files.ref}
          id="file_upload_button"
          type="button"
          class="relative block w-full rounded-lg border-2 border-dashed border-gray-300 p-12 text-center hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
        >
          <.icon name="hero-camera" class="mx-auto h-12 w-12 text-gray-400" />
          <span class="mt-2 block text-sm font-semibold text-gray-900">
            Click or Drop to Upload Photos
          </span>
          <.live_file_input upload={@uploads.files} class="hidden" />
        </button>
      </div>
    </form>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:section, "uploads")
     |> allow_upload(:files,
       writer: fn _name, entry, _socket ->
         {Ingest.Uploaders.Azure,
          name: entry.client_name, user_id: socket.assigns.current_user.id}
       end,
       auto_upload: true,
       progress: &handle_progress/3,
       accept: :any,
       max_entries: 100,
       max_file_size: 1_000_000_000_000_000,
       chunk_size: 5_242_880
     ), layout: {IngestWeb.Layouts, :dashboard}}
  end

  defp handle_progress(:files, entry, socket) do
    dbg(entry.progress)

    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{} = meta ->
          {:ok, meta}
        end)

      {:noreply,
       socket
       |> put_flash(:info, "file #{uploaded_file.filename} uploaded")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end
end
