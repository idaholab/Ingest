defmodule IngestWeb.MembersProjectShowLive do
  alias Ingest.Uploads
  alias Ingest.Projects.ProjectInvites
  alias Ingest.Projects
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl"><%= @project.name %></h1>
      <p><%= @project.description %></p>

      <div class="pr-5">
        <div class="relative mt-10">
          <div class="absolute inset-0 flex items-center" aria-hidden="true">
            <div class="w-full border-t border-gray-300"></div>
          </div>
          <div class="relative flex justify-center">
            <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
              Requests
            </span>
          </div>
        </div>

        <.table id="requests" rows={@project.requests}>
          <:col :let={request} label="Name"><%= request.name %></:col>
          <:col :let={request} label="Uploads"><%= get_upload_count(request) %></:col>
        </.table>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       :invite_form,
       to_form(Ingest.Projects.change_project_invites(%ProjectInvites{}))
     )
     |> assign(:section, "projects"), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    project = Projects.get_project!(id)

    {:noreply,
     socket
     |> assign(:project, project)}
  end

  defp get_upload_count(request) do
    Uploads.uploads_for_request_count(request)
  end
end
