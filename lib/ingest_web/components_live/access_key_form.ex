defmodule IngestWeb.LiveComponents.AccessKeyForm do
  @moduledoc """
  InviteModal is the modal for Inviting Users to Data Requests. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex flex-row justify-center">
        <button
          :if={!@key}
          phx-click="generate"
          phx-target={@myself}
          class="flex-shrink-0 rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          Generate Key
        </button>
      </div>

      <div :if={@key} class="rounded-md bg-green-50 p-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg
              class="h-5 w-5 text-green-400"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
              data-slot="icon"
            >
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-green-800">Key Generated!</h3>
            <div class="mt-2 text-sm text-green-700">
              <p>
                Save your secret access key in a safe place, as this will be the only time you will see it.
              </p>
              <p class="mt-2"><b>ACCESS KEY: </b>{@key.access_key}</p>
              <p class="mt-2"><b>SECRET ACCESS KEY: </b>{@key.secret_key}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:key, nil)
     |> assign(assigns)}
  end

  @impl true
  def handle_event("generate", _params, socket) do
    {:ok, key} = Ingest.Accounts.create_user_keys(socket.assigns.current_user)

    {:noreply, socket |> assign(:key, key)}
  end
end
