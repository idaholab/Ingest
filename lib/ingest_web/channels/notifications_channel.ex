defmodule IngestWeb.NotificationsChannel do
  @moduledoc """
  NotificationsChannel allows us to trigger updates on the notifications live component when a user receives
  new notifications. There doesn't need to be much here for now.
  """
  use IngestWeb, :channel

  @impl true
  def join("notifications:" <> user_id, _payload, socket) do
    if authorized?(user_id, socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(user_id, socket) do
    user_id == socket.assigns.current_user
  end
end
