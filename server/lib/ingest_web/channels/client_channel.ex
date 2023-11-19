defmodule IngestWeb.ClientChannel do
  @moduledoc """
  ClientChannel controls all aspects of the client interaction with the Phoenix server apart from the transfers.
  This allows users to interact with the central server and modify/view things on their client without us having to
  build a cross-platform UI for the Rust client.
  """
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

  @impl true
  def handle_in("dir_update", %{"directories" => dirs}, socket) do
    # for right now we're just going to shove whatever the client tells us into cachex for the dir
    # eventually we will need to pull the original, diff and update only the dirs we want, but I'm lazy rn
    Cachex.put(:clients, "dir:#{socket.assigns.client_id}", dirs)

    {:reply, :ok, socket}
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
