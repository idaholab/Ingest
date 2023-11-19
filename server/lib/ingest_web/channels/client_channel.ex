defmodule IngestWeb.ClientChannel do
  alias Ingest.Destinations
  use IngestWeb, :channel

  @impl true
  def join("client:" <> client_id, payload, socket) do
    if authorized?(client_id, socket.assigns.current_user) do
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

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (client:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # checks to see that the user_id contains the client_id the socket
  # is attempting to join on
  defp authorized?(client_id, user_id) do
    Destinations.get_client_for_user(client_id, user_id) != nil
  end
end
