defmodule IngestWeb.ProjectsLive do
  use IngestWeb, :live_view
  alias Ingest.Projects.Project

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:section, "projects")
     |> assign(:requests, [])
     |> stream_configure(:projects, dom_id: &elem(&1, 0).id)
     |> stream(:projects, Ingest.Projects.list_project_with_count())
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

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project_form, %Project{} |> Ecto.Changeset.change() |> to_form())
    |> assign(:project, %Project{})
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
    {:ok, _} = Ingest.Projects.delete_project(project)

    {:noreply, stream_delete(socket, :projects, {project, count})}
  end
end
