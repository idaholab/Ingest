defmodule IngestWeb.RequestsLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={!@requests || Enum.empty?(@requests)} class="text-center">
        <.icon name="hero-folder-plus" class="mx-auto h-12 w-12 text-gray-400" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No requests</h3>
        <p class="mt-1 text-sm text-gray-500">Get started by creating a new request.</p>
        <.link
          patch={~p"/dashboard/requests/new"}
          type="button"
          class="mt-5 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          <.icon name="hero-plus" /> New Request
        </.link>
      </div>

      <div :if={@requests && !Enum.empty?(@requests)} class="px-4 sm:px-6 lg:px-8">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-gray-900">Data Requests</h1>
            <p class="mt-2 text-sm text-gray-700">
              A list of all the data requests you have created or have access to. A data request is a combination of projects, templates, and destinations to make a cohesive request for data.
            </p>
          </div>
          <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
            <div class="mt-6">
              <.link patch={~p"/dashboard/requests/new"}>
                <button
                  type="button"
                  class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  <.icon name="hero-plus" /> New Request
                </button>
              </.link>
            </div>
          </div>
        </div>
        <div class="mt-8 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <.table
                id="requests"
                rows={@streams.requests}
                row_click={fn {_id, request} -> JS.navigate(~p"/dashboard/requests/#{request}") end}
              >
                <:col :let={{_id, request}} label="Name"><%= request.name %></:col>
                <:col :let={{_id, request}} label="Project"><%= request.project.name %></:col>
                <:col :let={{_id, request}} label="Description">
                  <%= request.description %>
                </:col>

                <:col :let={{_id, request}} label="Status"><%= request.status %></:col>

                <:action :let={{_id, request}}>
                  <.link
                    navigate={~p"/dashboard/requests/#{request}"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Show
                  </.link>
                </:action>
                <:action :let={{id, request}}>
                  <.link
                    class="text-red-600 hover:text-red-900"
                    phx-click={JS.push("delete", value: %{id: request.id}) |> hide("##{id}")}
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
      <.modal
        :if={@live_action in [:new]}
        id="request_modal"
        show
        on_cancel={JS.patch(~p"/dashboard/requests")}
      >
        <.live_component
          live_action={@live_action}
          request_form={@request_form}
          request={@request}
          module={IngestWeb.LiveComponents.RequestForm}
          id="request-modal-component"
          current_user={@current_user}
        />
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:section, "requests")
     |> assign(:requests, Ingest.Requests.list_own_requests(socket.assigns.current_user))
     |> stream(
       :requests,
       Ingest.Requests.list_own_requests(socket.assigns.current_user)
     ), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New request")
    |> assign(:request_form, %Ingest.Requests.Request{} |> Ecto.Changeset.change() |> to_form())
    |> assign(:request, %Ingest.Requests.Request{inserted_by: socket.assigns.current_user.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing requests")
    |> assign(:request, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    request = Ingest.Requests.get_request!(id)
    {:ok, _} = Ingest.Requests.delete_request(request)

    {:noreply, stream_delete(socket, :requests, request)}
  end
end
