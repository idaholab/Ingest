defmodule IngestWeb.LiveComponents.RequestForm do
  @moduledoc """
  RequestModal is the modal for creating/editing Data Requests. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@request_form}
        phx-change="validate"
        phx-target={@myself}
        id="request"
        phx-submit="save"
      >
        <div class="space-y-12">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">New Data Request</h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                A Data Request is a combination of projects, destinations, and metadata templates. This combination will allow users to request actual data from public or private users and have that data uploaded to a final destination with the metadata. After you make your request you will have the opportunity to assign projects and templates.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.label for="status-select">
                  Request Name
                </.label>
                <.input type="text" field={@request_form[:name]} />
              </div>

              <div class="sm:col-span-4">
                <.label for="status-select">
                  Project
                </.label>
                <.input type="select" options={@options} field={@request_form[:project_id]} />
              </div>

              <div class="col-span-full">
                <.label for="request-description">
                  Request Description
                </.label>
                <.input type="textarea" field={@request_form[:description]} />

                <p class="mt-3 text-sm leading-6 text-gray-600">
                  Write a few sentences about your request.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.button
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            phx-disable-with="Saving..."
          >
            Save
          </.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{request: request} = assigns, socket) do
    changeset = Ingest.Requests.change_request(request)
    projects = Ingest.Projects.list_own_projects_with_count(assigns.current_user.id)

    options = Enum.map(projects, fn {p, _c} -> {p.name, p.id} end) |> Map.new()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:options, options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"request" => request_params}, socket) do
    changeset =
      socket.assigns.request
      |> Ingest.Requests.change_request(request_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    save_request(socket, socket.assigns.live_action, request_params)
  end

  defp save_request(socket, :edit, request_params) do
    case Ingest.Requests.update_request(socket.assigns.request, request_params) do
      {:ok, request} ->
        notify_parent({:saved, request})

        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_request(socket, :new, request_params) do
    case Map.put(request_params, "inserted_by", socket.assigns.current_user.id)
         |> Map.put("status", :draft)
         |> Ingest.Requests.create_request() do
      {:ok, request} ->
        {:noreply,
         socket
         |> put_flash(:info, "request created successfully")
         |> redirect(to: ~p"/dashboard/requests/#{request.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :request_form, to_form(changeset))
  end

  defp(notify_parent(msg), do: send(self(), {__MODULE__, msg}))
end
