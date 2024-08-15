defmodule IngestWeb.UserManagementLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-base font-semibold leading-6 text-gray-900">Users</h1>
          <p class="mt-2 text-sm text-gray-700">
            Manage the users of the system.
          </p>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
          <div class="mt-6">
            <.link patch={~p"/dashboard/projects/new"}>
              <button
                type="button"
                class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                <.icon name="hero-plus" /> New Project
              </button>
            </.link>
          </div>
        </div>
      </div>
      <div class="mt-8 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            <.table
              id="users"
              rows={@streams.users}
              row_click={fn {_id, user} -> JS.navigate(~p"/dev/users/#{user}") end}
            >
              <:col :let={{_id, user}} label="Name"><%= user.name %></:col>

              <:col :let={{_id, user}} label="Email">
                <%= user.email %>
              </:col>

              <:col :let={{_id, user}} label="Role"><%= user.roles %></:col>

              <:action :let={{_id, user}}>
                <.link patch={~p"/dev/users/#{user}"} class="text-indigo-600 hover:text-indigo-900">
                  Edit
                </.link>
              </:action>
              <:action :let={{id, user}}>
                <.link
                  class="text-red-600 hover:text-red-900"
                  phx-click={JS.push("delete", value: %{id: user.id}) |> hide("##{id}")}
                  data-confirm="Are you sure?"
                >
                  Delete
                </.link>
              </:action>
            </.table>
          </div>
        </div>
      </div>
    </div>
    <.modal :if={@live_action in [:edit]} id="user_modal" show on_cancel={JS.patch(~p"/dev/users")}>
      <.live_component
        live_action={@live_action}
        user={@user}
        module={IngestWeb.LiveComponents.UserEditForm}
        id="user-modal-component"
        patch={~p"/dev/users"}
        current_user={@current_user}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "users"), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Ingest.Accounts.get_user!(id)
    Ingest.Accounts.delete_user!(user)

    {:noreply, stream_delete(socket, :users, user)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> stream(:users, Ingest.Accounts.list_users())
    |> assign(:project, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Ingest.Accounts.get_user!(id))
  end
end
