defmodule IngestWeb.LiveComponents.ProjectForm do
  @moduledoc """
  Project Modal is the modal for creating/editing Projects. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  # TODO: I've made a good start on this to show you how it should work, but this should be the last form you do, project creation and templates come first
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@project_form}
        phx-change="validate"
        phx-target={@myself}
        id="project"
        phx-submit="save"
      >
        <div class="space-y-12">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">New Project</h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Create a new Project. A Project is a logical grouping of data requests and will be represented in how the data is sent to the configured data destination.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.label for="status-select" class="block text-sm font-medium leading-6 text-gray-900">
                  Project Name
                </.label>
                <.input type="text" field={@project_form[:name]} />
              </div>

              <div class="col-span-full">
                <.label for="project-description">
                  Project Description
                </.label>
                <.input type="textarea" field={@project_form[:description]} />

                <p class="mt-3 text-sm leading-6 text-gray-600">
                  Write a few sentences about your project.
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
  def update(%{project: project} = assigns, socket) do
    changeset = Ingest.Projects.change_project(project)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      socket.assigns.project
      |> Ingest.Projects.change_project(project_params)
      |> Map.put(:action, :validate)

    dbg(changeset)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.live_action, project_params)
  end

  defp save_project(socket, :edit, project_params) do
    case Ingest.Projects.update_project(socket.assigns.project, project_params) do
      {:ok, project} ->
        notify_parent({:saved, project})

        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_project(socket, :new, project_params) do
    case Map.put(project_params, "inserted_by", socket.assigns.current_user.id)
         |> Ingest.Projects.create_project() do
      {:ok, project} ->
        notify_parent({:saved, project})

        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :project_form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
