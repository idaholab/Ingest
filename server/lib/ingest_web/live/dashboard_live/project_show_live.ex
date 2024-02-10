defmodule IngestWeb.ProjectShowLive do
  alias Ingest.Projects.ProjectInvites
  alias Ingest.Projects
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl"><%= @project.name %></h1>
      <p><%= @project.description %></p>
      <div class="grid grid-cols-2">
        <div class="pr-5 border-r-2">
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
            <:col label="Uploads">10</:col>

            <:action :let={_request}>
              <.link class="text-indigo-600 hover:text-indigo-900">
                Edit
              </.link>
            </:action>
            <:action :let={_request}>
              <.link data-confirm="Are you sure?" class="text-red-600 hover:text-red-900">
                Delete
              </.link>
            </:action>
          </.table>
        </div>

        <div class="pl-5">
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Members
              </span>
            </div>
          </div>

          <div>
            <ul role="list" class="divide-y divide-gray-100">
              <%= for member <- @project.project_members do %>
                <li class="flex items-center justify-between gap-x-6 py-5">
                  <div class="flex min-w-0 gap-x-4">
                    <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-500">
                      <span class="font-medium leading-none text-white">
                        <%= String.slice(member.name, 0..1) |> String.upcase() %>
                      </span>
                    </span>
                    <div class="min-w-0 flex-auto">
                      <p class="text-sm font-semibold leading-6 text-gray-900"><%= member.name %></p>
                      <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                        <%= member.email %>
                      </p>
                    </div>
                  </div>
                  <div>
                    <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                      <%= Atom.to_string(
                        Enum.find(member.project_roles, fn project_roles ->
                          project_roles.project_id == @project.id
                        end).role
                      )
                      |> String.capitalize() %>
                    </span>

                    <span
                      data-confirm="Are you sure?"
                      phx-click="remove_member"
                      phx-value-member={member.id}
                      phx-value-project={@project.id}
                      class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 cursor-pointer"
                    >
                      Remove
                    </span>
                  </div>
                </li>
              <% end %>
            </ul>

            <div class="mx-auto max-w-lg mt-44">
              <div>
                <div class="text-center">
                  <svg
                    class="mx-auto h-12 w-12 text-gray-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 48 48"
                    aria-hidden="true"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M34 40h10v-4a6 6 0 00-10.712-3.714M34 40H14m20 0v-4a9.971 9.971 0 00-.712-3.714M14 40H4v-4a6 6 0 0110.713-3.714M14 40v-4c0-1.313.253-2.566.713-3.714m0 0A10.003 10.003 0 0124 26c4.21 0 7.813 2.602 9.288 6.286M30 14a6 6 0 11-12 0 6 6 0 0112 0zm12 6a4 4 0 11-8 0 4 4 0 018 0zm-28 0a4 4 0 11-8 0 4 4 0 018 0z"
                    />
                  </svg>
                  <h2 class="mt-2 text-base font-semibold leading-6 text-gray-900">
                    Add team members
                  </h2>
                  <p class="mt-1 text-sm text-gray-500">
                    As the owner of this project, you can manage team members and their  permissions.
                  </p>
                </div>
                <div class="flex">
                  <.simple_form
                    id="invite_form"
                    for={@invite_form}
                    phx-change="validate_invite"
                    phx-submit="send_invite"
                    class="w-full"
                  >
                    <.label>Email address</.label>
                    <.input type="email" field={@invite_form[:email]} />

                    <button
                      type="submit"
                      class="ml-4 flex-shrink-0 rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    >
                      Send invite
                    </button>
                  </.simple_form>
                </div>
              </div>
            </div>
            <div class="pr-5 border-r-2">
              <div class="relative mt-10">
                <div class="absolute inset-0 flex items-center" aria-hidden="true">
                  <div class="w-full border-t border-gray-300"></div>
                </div>
                <div class="relative flex justify-center">
                  <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                    Outstanding Invites
                  </span>
                </div>
              </div>

              <.table id="invites" rows={@project.invites}>
                <:col :let={invite} label="Email">
                  <%= if Ecto.assoc_loaded?(invite.invited_user) do
                    invite.invited_user.email
                  else
                    invite.email
                  end %>
                </:col>

                <:action :let={invite}>
                  <.link
                    phx-click="delete_invite"
                    phx-value-id={invite.id}
                    data-confirm="Are you sure?"
                    class="text-red-600 hover:text-red-900"
                  >
                    Revoke
                  </.link>
                </:action>
              </.table>
            </div>
          </div>
        </div>
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
    {:noreply, socket |> assign(:project, project) |> assign(:invites, project.invites)}
  end

  @impl true
  def handle_event("remove_member", %{"member" => member, "project" => project}, socket) do
    {_count, _pm} =
      Projects.get_member_project(member, project)
      |> Projects.remove_project_member()

    {:noreply, socket |> assign(:project, Projects.get_project!(project))}
  end

  @impl true
  def handle_event("delete_invite", %{"id" => id}, socket) do
    Projects.delete_project_invites(Projects.get_project_invites!(id))
    {:noreply, socket |> push_patch(to: ~p"/dashboard/projects/#{socket.assigns.project}")}
  end

  @impl true
  def handle_event("validate_invite", %{"project_invites" => invite_params}, socket) do
    changeset =
      Projects.change_project_invites(%ProjectInvites{}, invite_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:invite_form, to_form(changeset))}
  end
end
