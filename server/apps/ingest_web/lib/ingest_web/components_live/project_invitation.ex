defmodule IngestWeb.LiveComponents.ProjectInvitation do
  alias Ingest.Projects
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-4 py-5 sm:p-6">
      <h3 class="text-base font-semibold leading-6 text-gray-900">Project Invitation</h3>
      <div class="mt-2 max-w-xl text-sm text-gray-500">
        <p>
          You've been invited to join {@project.name} as a member. Please accept or ignore the invitation by clicking the buttons below.
        </p>
      </div>
      <div class="mt-5">
        <button
          type="button"
          phx-target={@myself}
          phx-click="accept"
          class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
        >
          Accept Invite
        </button>
        <button
          type="button"
          phx-target={@myself}
          phx-click="reject"
          class="inline-flex items-center rounded-md bg-gray-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
        >
          Ignore
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("accept", _params, socket) do
    {:ok, _pm} = Projects.add_user_to_project(socket.assigns.project, socket.assigns.current_user)
    Projects.delete_all_invites(socket.assigns.project, socket.assigns.current_user)

    {:noreply, socket |> push_navigate(to: ~p"/dashboard/projects/#{socket.assigns.project.id}")}
  end

  @impl true
  def handle_event("reject", _params, socket) do
    Projects.delete_all_invites(socket.assigns.project, socket.assigns.current_user)
    {:noreply, socket |> push_patch(to: socket.assigns.patch)}
  end
end
