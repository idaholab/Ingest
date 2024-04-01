defmodule IngestWeb.LiveComponents.ImportData do
  @moduledoc """
  InviteModal is the modal for Inviting Users to Data Requests. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-center">
      <button
        class="mt-5 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        type="button"
        phx-click="import-box-data"
        phx-target={@myself}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2"
          stroke="currentColor"
          class="w-5 h-5 mr-1"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M12 16.5V9.75m0 0l3 3m-3-3l-3 3M6.75 19.5a4.5 4.5 0 01-1.41-8.775 5.25 5.25 0 0110.233-2.33 3 3 0 013.758 3.848A3.752 3.752 0 0118 19.5H6.75z"
          >
          </path>
        </svg>
        Import Via Box
      </button>
    </div>
    """
  end

  def update(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("import-box-data", _params, socket) do
    auth_url = Ingest.OAuth.Util.get_auth_url()
    dbg(auth_url)

    {:noreply,
     socket
     |> redirect(external: auth_url)}
  end
end
