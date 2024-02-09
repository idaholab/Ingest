defmodule IngestWeb.ComponentsLive.NotificationsBarLive do
  alias Ingest.Accounts
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id="notifications_bar_live" phx-hook="Notifications">
      <button
        type="button"
        phx-click={
          JS.toggle(
            to: "#notifications_menu",
            in: {"ease-out duration-100", "opacity-0 scale-95", "opacity-100 scale-100"},
            out: {"ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
          )
        }
        phx-click-away={
          JS.hide(
            to: "#notifications_menu",
            transition: {"ease-in duration-75", "opacity-100 scale-100", "opacity-0 scale-95"}
          )
        }
        class="-m-2.5 p-2.5 text-gray-400 hover:text-gray-500"
      >
        <span class="sr-only">View notifications</span>
        <svg
          class="h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          aria-hidden="true"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0"
          />
        </svg>
      </button>

      <div
        id="notifications_menu"
        class="hidden absolute right-40 z-10 mt-2.5 w-100 origin-top-right rounded-md bg-white py-2 shadow-lg ring-1 ring-gray-900/5 focus:outline-none"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby="user-menu-button"
        tabindex="-1"
      >
        <div class="mx-5" id="notifications" phx-update="stream">
          <ul role="list" class="divide-y divide-gray-100">
            <li class="hidden last:block">
              No Notifications
            </li>
            <li :for={{dom_id, notification} <- @streams.notifications} class="py-4" id={dom_id}>
              <div class="flex items-center gap-x-3">
                <h3 class="flex-auto truncate text-sm font-semibold leading-6 text-gray-900">
                  <%= notification.subject %>
                </h3>
                <time datetime="2023-01-23T11:00" class="flex-none text-xs text-gray-500">
                  <%= Timex.format!(notification.inserted_at, "{UNIX}") %>
                </time>

                <.link
                  phx-click={
                    JS.push("delete_notification", value: %{id: notification.id}, target: @myself)
                    |> hide("##{dom_id}")
                  }
                  phx-target={@myself}
                  class="hover:text-red-900"
                >
                  <.icon name="hero-x-mark" />
                </.link>
              </div>
              <p class="mt-3 truncate text-sm text-gray-500 truncate">
                <%= notification.body %>
              </p>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:current_user, assigns.current_user)
     |> stream(:notifications, Accounts.list_own_notifications(assigns.current_user))}
  end

  @impl true
  def handle_event("new_notification", unsigned_params, socket) do
    IngestWeb.Endpoint.broadcast(
      "notifications:#{socket.assigns.current_user.id}",
      "new_notification",
      %{}
    )

    {:noreply, socket}
  end

  def handle_event("delete_notification", %{"id" => id}, socket) do
    notification = Accounts.get_notifications!(id)

    case Accounts.delete_notifications(notification) do
      {:ok, _n} ->
        {:noreply, socket |> stream_delete(:notifications, notification)}

      {:error, _e} ->
        {:noreply, socket |> put_flash(:error, "Unable to delete notification")}
    end

    {:noreply, socket}
  end
end
