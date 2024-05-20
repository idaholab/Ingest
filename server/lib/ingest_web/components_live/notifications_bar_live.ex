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
        <.icon :if={!@has_notifications} name="hero-bell" class="h-6 w-6" />
        <.icon :if={@has_notifications} name="hero-bell-alert" class="h-6 w-6 bg-green-900 " />
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
            <li
              :for={{dom_id, notification} <- @streams.notifications}
              class="py-4 cursor-pointer"
              id={dom_id}
              phx-click="select"
              phx-value-id={notification.id}
              phx-target={@myself}
            >
              <span
                :if={!notification.seen}
                class="inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20"
              >
                New!
              </span>
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
    notifications = Accounts.list_own_notifications(assigns.current_user)

    {:ok,
     socket
     |> assign(:current_user, assigns.current_user)
     |> assign(:has_notifications, Enum.filter(notifications, fn n -> !n.seen end) != [])
     |> stream(:notifications, notifications)}
  end

  @impl true
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

  @impl true
  def handle_event("new_notification", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:has_notifications, true)
     |> stream_insert(:notifications, Accounts.get_notifications!(id))}
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    notification = Accounts.get_notifications!(id)
    dbg(notification)
    Accounts.delete_notifications(notification)

    if notification.action_link == nil do
      {:noreply, socket |> stream_delete(:notifications, notification)}
    else
      {:noreply, socket |> push_navigate(to: notification.action_link)}
    end
  end
end
