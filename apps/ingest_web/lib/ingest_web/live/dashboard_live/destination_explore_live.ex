defmodule IngestWeb.DestinationExploreLive do
  use IngestWeb, :live_view

  alias Ingest.Destinations

  @impl true
  def render(assigns) do
    ~H"""
    <p>Hello from DestinationExploreLive!</p>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "destinations"), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    destination = Destinations.get_destination!(id)

    if destination.type !== :s3 && destination.type !== :lakefs do
      {:noreply,
       socket
       |> put_flash(:error, "Explore not supported for this destination type")
       |> redirect(to: ~p"/dashboard/destinations")}
    else
      {:noreply, socket}
    end
  end
end
