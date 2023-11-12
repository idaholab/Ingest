defmodule IngestWeb.DestinationsLive do
  @moduledoc """
  The destinations live component is in charge of handling both the shared destinations created by an administrator
  such as the Project Alexandria storage for NA-22 data or INL HPC, and the shared/owned Ingest Clients known by
  the user. This is the entry point for managing your data destinations prior to hooking them up to a data request.
  """
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal
        :if={@live_action == :register_client}
        id="register_client_modal"
        show
        on_cancel={JS.patch(~p"/dashboard/destinations")}
      >
        hi
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "destinations"), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :register_client, %{"client_id" => client_id}) do
    socket
    |> assign(:page_title, "Register")
    |> assign(:project, nil)
  end

  # need to cover the index action TODO: find a better way of streamlining this
  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Data Destinations")
  end
end
