defmodule IngestWeb.ProjectsLive do
  alias Ingest.Projects
  use IngestWeb, :live_view
  alias Ingest.Projects.Project

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-base font-semibold leading-6 text-gray-900">Projects</h1>
          <p class="mt-2 text-sm text-gray-700">
            A list of all the projects you own or are a part of. Projects typically reflect a logical separation between groups of data requests.
          </p>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
          <div class="mt-6">
            <.link patch={~p"/dashboard/projects/new"}>
              <button
                type="button"
                class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                <.icon name="hero-plus" /> New Project
              </button>
            </.link>
          </div>
        </div>
      </div>
      <div class="mt-8 flow-root">
        <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            <.table
              id="projects"
              rows={@streams.projects}
              row_click={
                fn {_id, {project, _count}} -> JS.navigate(~p"/dashboard/projects/#{project}") end
              }
            >
              <:col :let={{_id, {project, _count}}} label="Name"><%= project.name %></:col>
              <:col :let={{_id, {project, _count}}} label="Description">
                <%= project.description %>
              </:col>
              <:col :let={{_id, {_project, count}}} label="Request Count"><%= count %></:col>
              <:col :let={{_id, {project, _count}}} label="Role">
                <%= if project.inserted_by == @current_user.id do
                  "Owner"
                else
                  "Member"
                end %>
              </:col>
              <:action :let={{_id, {project, _count}}}>
                <div class="sr-only">
                  <.link
                    navigate={~p"/dashboard/projects/#{project}"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Show
                  </.link>
                </div>
                <.link
                  patch={~p"/dashboard/projects/#{project}/edit"}
                  class="text-indigo-600 hover:text-indigo-900"
                >
                  Edit
                </.link>
              </:action>
              <:action :let={{id, {project, count}}}>
                <.link
                  class="text-red-600 hover:text-red-900"
                  phx-click={
                    JS.push("delete", value: %{id: project.id, count: count}) |> hide("##{id}")
                  }
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
      :if={@live_action in [:new, :edit]}
      id="project_modal"
      show
      on_cancel={JS.patch(~p"/dashboard/projects")}
    >
      <.live_component
        live_action={@live_action}
        project={@project}
        module={IngestWeb.LiveComponents.ProjectForm}
        id="request-modal-component"
        patch={~p"/dashboard/projects"}
        current_user={@current_user}
      />
    </.modal>

    <.modal
      :if={@live_action in [:invite]}
      id="invite_modal"
      show
      on_cancel={JS.patch(~p"/dashboard/projects")}
    >
      <.live_component
        live_action={@live_action}
        project={@project}
        module={IngestWeb.LiveComponents.ProjectInvitation}
        id="invite-modal-component"
        patch={~p"/dashboard/projects"}
        current_user={@current_user}
      />
    </.modal>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:section, "projects")
     |> assign(:requests, [])
     |> stream_configure(:projects, dom_id: &elem(&1, 0).id)
     |> stream(
       :projects,
       Ingest.Projects.list_own_projects_with_count(socket.assigns.current_user.id)
     )
     |> apply_action(socket.assigns.live_action, params), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Project")
    |> assign(:project, Ingest.Projects.get_project!(id))
  end

  defp apply_action(socket, :invite, %{"id" => id}) do
    invites =
      Projects.list_project_invites_user(Projects.get_project!(id), socket.assigns.current_user)

    if invites == [] do
      socket |> push_navigate(to: ~p"/dashboard/projects")
    else
      socket
      |> assign(:page_title, "Accept Project Invite")
      |> assign(:project, Ingest.Projects.get_project!(id))
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project_form, %Project{} |> Ecto.Changeset.change() |> to_form())
    |> assign(:project, %Project{inserted_by: socket.assigns.current_user.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Projects")
    |> assign(:project, nil)
  end

  @impl true
  def handle_info({IngestWeb.LiveComponents.ProjectForm, {:saved, project}}, socket) do
    {:noreply, stream_insert(socket, :projects, {project, 0})}
  end

  @impl true
  def handle_event("delete", %{"id" => id, "count" => count}, socket) do
    project = Ingest.Projects.get_project!(id)

    with :ok <-
           Bodyguard.permit(
             Ingest.Projects.Project,
             :delete_project,
             socket.assigns.current_user,
             project
           ),
         {:ok, _} <- Ingest.Projects.delete_project(project) do
      {:noreply, stream_delete(socket, :projects, {project, count})}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Unable to delete project")}
    end
  end
end
