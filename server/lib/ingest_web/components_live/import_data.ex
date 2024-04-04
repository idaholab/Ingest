defmodule IngestWeb.LiveComponents.ImportData do
  @moduledoc """
  InviteModal is the modal for Inviting Users to Data Requests. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  alias Ingest.OAuth.Util

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if !authed(@current_user) do %>
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
      <% else %>
        <div class="px-4 sm:px-6 lg:px-8">
          <div class="sm:flex sm:items-center">
            <div class="sm:flex-auto">
              <h1 class="text-base font-semibold leading-6 text-gray-900">Folders</h1>
              <p class="mt-2 text-sm text-gray-700">
                A list of all the folders in your Box.com account.
              </p>
            </div>
            <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
              <button
                type="button"
                class="block rounded-md bg-indigo-600 px-3 py-2 text-center text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                Import Folder
              </button>
            </div>
          </div>
          <div class="mt-8 flow-root">
            <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 sm:rounded-lg">
                  <table class="min-w-full divide-y divide-gray-300">
                    <thead class="bg-gray-50">
                      <tr>
                        <th
                          scope="col"
                          class="py-3.5 pl-4 text-left text-sm font-semibold text-gray-900 sm:pl-6"
                        >
                          Folder
                        </th>
                        <th scope="col" class="py-3.5 text-left text-sm font-semibold text-gray-900">
                          Select
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 bg-white">
                      <%= for folder <- fetch_root_folders(@current_user) do %>
                        <tr>
                          <td class="whitespace-nowrap py-4 pl-4 text-sm font-medium text-gray-900 sm:pl-6">
                            <%= folder["name"] %>
                          </td>
                          <td class="whitespace-nowrap py-4 text-sm text-gray-500">
                            <div class="ml-3 flex h-6 items-center">
                              <input
                                id="account-savings"
                                aria-describedby="account-savings-description"
                                name="account"
                                type="radio"
                                class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                              />
                            </div>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns)}
  end

  @impl true
  def handle_event("import-box-data", _params, socket) do
    auth_url = Ingest.OAuth.Util.get_auth_url()

    {:noreply,
     socket
     |> redirect(external: auth_url)}
  end

  def fetch_root_folders(current_user) do
    {:ok, {access_token, _refresh_token}} =
      Cachex.get(:server, "Box_Tokens:#{current_user.id}")

    headers = %{
      "authorization" => "Bearer #{access_token}"
    }

    folders =
      Req.get!("https://api.box.com/2.0/folders/0",
        headers: headers,
        connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
      )

    folders.body["item_collection"]["entries"]
  end

  defp authed(current_user) do
    {:ok, {_access_token, refresh_token}} =
      Cachex.get(:server, "Box_Tokens:#{current_user.id}")

    Util.refresh_access_token(refresh_token, current_user.id)
  end
end
