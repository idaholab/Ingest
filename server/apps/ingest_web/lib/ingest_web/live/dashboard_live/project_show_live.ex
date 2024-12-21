defmodule IngestWeb.ProjectShowLive do
  alias Ingest.Uploads
  alias Ingest.Accounts
  alias Ingest.Projects.ProjectInvites
  alias Ingest.Projects
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl">{@project.name}</h1>
      <p>{@project.description}</p>
      <div class="grid grid-cols-2">
        <div class="pr-5 border-r-2">
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Active Data Requests
              </span>
            </div>
          </div>

          <.table id="requests" rows={@project.requests}>
            <:col :let={request} label="Name">{request.name}</:col>
            <:col :let={request} label="Uploads">{get_upload_count(request)}</:col>

            <:action :let={request}>
              <.link
                navigate={~p"/dashboard/requests/#{request}"}
                class="text-indigo-600 hover:text-indigo-900"
              >
                View
              </.link>
            </:action>
            <:action :let={request}>
              <.link
                :if={
                  Bodyguard.permit?(Ingest.Projects.Project, :update_project, @current_user, @project)
                }
                patch={~p"/dashboard/requests/#{request}"}
                class="text-indigo-600 hover:text-indigo-900"
              >
                Edit
              </.link>
            </:action>
            <:action :let={request}>
              <.link
                :if={
                  Bodyguard.permit?(Ingest.Projects.Project, :update_project, @current_user, @project)
                }
                data-confirm="Are you absolutely sure you want to delete this Data Request?"
                phx-value-id={request.id}
                phx-click={
                  JS.push("remove_request", value: %{id: request.id})
                  |> hide("##{request.id}")
                }
                class="text-red-600 hover:text-red-900"
              >
                Delete
              </.link>
            </:action>
          </.table>
          <div class="relative mt-20">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Default Metadata Collection Forms
              </span>
            </div>
          </div>

          <.table id="templates" rows={@streams.templates}>
            <:col :let={{_id, template}} label="Name">{template.name}</:col>

            <:action :let={{_id, template}}>
              <.link
                :if={
                  Bodyguard.permit?(Ingest.Projects.Project, :update_project, @current_user, @project)
                }
                data-confirm={check_use(@project, "Template")}
                phx-value-id={template.id}
                class="text-red-600 hover:text-red-900"
                phx-click={
                  JS.push("remove_template", value: %{id: template.id})
                  |> hide("##{template.id}")
                }
              >
                Remove
              </.link>
            </:action>
          </.table>

          <div class="relative flex justify-center mt-10">
            <.link
              :if={
                Bodyguard.permit?(Ingest.Projects.Project, :update_project, @current_user, @project)
              }
              patch={~p"/dashboard/projects/#{@project.id}/search/templates"}
            >
              <button
                type="button"
                class="inline-flex items-center rounded-md bg-gray-600 hover:text-white text-black px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-gray-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
              >
                <.icon name="hero-plus" /> Find Metadata Collection Form
              </button>
            </.link>
          </div>
          <div class="relative mt-20">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Default Data Destination
              </span>
            </div>
          </div>

          <div>
            <ul role="list" class="divide-y divide-gray-100">
              <%= for {_id, destination} <- @streams.destinations do %>
                <li class="flex items-center justify-between gap-x-6 py-5">
                  <div class="flex min-w-0 gap-x-4">
                    <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-500">
                      <span class="font-medium leading-none text-white">
                        <span :if={destination.type == :s3}>S3</span>
                        <span :if={destination.type == :azure}>AZ</span>
                        <span :if={destination.type == :internal}>I</span>
                      </span>
                    </span>
                    <div class="min-w-0 flex-auto">
                      <p class="text-sm font-semibold leading-6 text-gray-900">
                        {destination.name}
                      </p>
                      <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                        {destination.type}
                      </p>
                    </div>
                  </div>
                  <div>
                    <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                      Active
                    </span>

                    <span
                      :if={
                        Bodyguard.permit?(
                          Ingest.Projects.Project,
                          :update_project,
                          @current_user,
                          @project
                        )
                      }
                      data-confirm={check_use(@project, "Destination")}
                      phx-click="remove_destination"
                      phx-value-id={destination.id}
                      phx-click={
                        JS.push("remove_destination", value: %{id: destination.id})
                        |> hide("##{destination.id}")
                      }
                      class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 cursor-pointer"
                    >
                      Remove
                    </span>
                  </div>
                </li>
              <% end %>
            </ul>

            <div class="relative flex justify-center mt-10">
              <.link
                :if={
                  Bodyguard.permit?(Ingest.Projects.Project, :update_project, @current_user, @project)
                }
                patch={~p"/dashboard/projects/#{@project.id}/search/destinations"}
              >
                <button
                  type="button"
                  class="inline-flex items-center rounded-md bg-gray-600 px-3 py-2 text-sm text-black hover:text-white font-semibold text-white shadow-sm hover:bg-gray-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  <.icon name="hero-plus" /> Find Data Destination
                </button>
              </.link>
            </div>
          </div>
        </div>

        <div class="pl-5">
          <div class="relative mt-10">
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center">
              <span class="bg-white px-3 text-base font-semibold leading-6 text-gray-900">
                Owner
              </span>
            </div>
          </div>

          <ul role="list" class="divide-y divide-gray-100">
            <li class="flex items-center justify-between gap-x-6 py-5">
              <div class="flex min-w-0 gap-x-4">
                <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-500">
                  <span class="font-medium leading-none text-white">
                    {if @project.user.name do
                      String.slice(@project.user.name, 0..1) |> String.upcase()
                    end}
                  </span>
                </span>
                <div class="min-w-0 flex-auto">
                  <p class="text-sm font-semibold leading-6 text-gray-900">
                    {@project.user.name}
                  </p>
                  <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                    {@project.user.email}
                  </p>
                </div>
              </div>
              <div>
                <span class="inline-flex items-center rounded-md  px-2 py-1 text-xs font-medium  ring-1 ring-inset ring-red-600/10">
                  Owner
                </span>
              </div>
            </li>
          </ul>

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
            <.table id="members" rows={@members}>
              <:col :let={member} label="Member">{member.user.email}</:col>
              <:col :let={member} label="Role">
                <.form for={} phx-change="update_role" phx-value-member={member.user.id}>
                  <.input
                    name="role"
                    type="select"
                    value={member.role}
                    prompt="Select one"
                    options={[Member: :member, Manager: :manager, "Co-Owner": :owner]}
                  />
                </.form>
              </:col>

              <:action :let={member}>
                <span
                  :if={
                    Bodyguard.permit?(
                      Ingest.Projects.Project,
                      :update_project,
                      @current_user,
                      @project
                    ) || member.id == @current_user.id
                  }
                  data-confirm="Are you sure?"
                  phx-click="remove_member"
                  phx-value-member={member.user.id}
                  phx-value-project={@project.id}
                  class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 cursor-pointer"
                >
                  Remove
                </span>
              </:action>
            </.table>

            <div
              :if={
                Bodyguard.permit?(
                  Ingest.Projects.Project,
                  :update_project,
                  @current_user,
                  @project
                )
              }
              class="pr-5 border-r-2 pt-10"
            >
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
                  {if Ecto.assoc_loaded?(invite.invited_user) && invite.invited_user do
                    invite.invited_user.email
                  else
                    invite.email
                  end}
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
            <div
              :if={
                Bodyguard.permit?(
                  Ingest.Projects.Project,
                  :update_project,
                  @current_user,
                  @project
                )
              }
              class="mx-auto max-w-lg mt-10"
            >
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
          </div>
        </div>
      </div>
    </div>

    <.modal
      :if={@live_action in [:search_destinations, :search_templates]}
      id="project-search_modal"
      show
      on_cancel={JS.patch(~p"/dashboard/projects/#{@project.id}")}
    >
      <.live_component
        live_action={@live_action}
        project={@project}
        module={IngestWeb.LiveComponents.ProjectSearchForm}
        id="project-search-modal-component"
        patch={"/dashboard/projects/#{@project.id}"}
        current_user={@current_user}
      />
    </.modal>
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
    project = Projects.get_owned_project!(socket.assigns.current_user, id)

    {:noreply,
     socket
     |> stream(:destinations, project.destinations)
     |> stream(:templates, project.templates)
     |> assign(:project, project)
     |> assign(:members, Projects.list_project_members(project))
     |> assign(:invites, project.invites)}
  end

  @impl true
  def handle_event("remove_member", %{"member" => member, "project" => project}, socket) do
    {_count, _pm} =
      Projects.get_member_project(member, project)
      |> Projects.remove_project_member()

    {:noreply,
     socket |> assign(:project, Projects.get_owned_project!(socket.assigns.current_user, project))}
  end

  @impl true
  def handle_event("delete_invite", %{"id" => id}, socket) do
    Projects.delete_project_invites(Projects.get_project_invites!(id))
    {:noreply, socket |> push_patch(to: ~p"/dashboard/projects/#{socket.assigns.project}")}
  end

  @impl true
  def handle_event("remove_request", %{"id" => id}, socket) do
    Ingest.Requests.delete_request(Ingest.Requests.get_request!(id))

    {:noreply,
     socket
     |> push_patch(to: ~p"/dashboard/projects/#{socket.assigns.project}")
     |> put_flash(:info, "Request Deleted Successfully")}
  end

  @impl true
  def handle_event("validate_invite", %{"project_invites" => invite_params}, socket) do
    changeset =
      Projects.change_project_invites(%ProjectInvites{}, invite_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:invite_form, to_form(changeset))}
  end

  @impl true
  def handle_event("send_invite", %{"project_invites" => invite_params}, socket) do
    email = Map.get(invite_params, "email")
    user = Accounts.get_user_by_email(email)

    if is_nil(email) || is_nil(user) do
      {:ok, i} = Projects.invite_by_email(socket.assigns.project, email)

      Ingest.Projects.ProjectNotifier.notify_project_invite(
        i.email,
        socket.assigns.project,
        IngestWeb.Endpoint.url()
      )
    else
      {:ok, i} = Projects.invite(socket.assigns.project, user)

      Ingest.Projects.ProjectNotifier.notify_project_invite(
        i.email,
        socket.assigns.project,
        IngestWeb.Endpoint.url()
      )

      IngestWeb.Notifications.notify(:project_invite, user, socket.assigns.project)
    end

    {:noreply,
     socket
     |> push_patch(to: ~p"/dashboard/projects/#{socket.assigns.project}")
     |> put_flash(:info, "Invite sent successfully")}
  end

  @impl true
  def handle_event("remove_destination", %{"id" => id}, socket) do
    destination = Ingest.Destinations.get_destination!(id)

    {1, _} = Ingest.Projects.remove_destination(socket.assigns.project, destination)

    {:noreply,
     stream_delete(socket, :destinations, destination)
     |> push_patch(to: "/dashboard/projects/#{socket.assigns.project.id}")}
  end

  @impl true
  def handle_event("remove_template", %{"id" => id}, socket) do
    template = Ingest.Projects.get_template!(id)
    {deleted_count, _} = Ingest.Projects.remove_template(socket.assigns.project, template)

    case deleted_count do
      1 ->
        {:noreply,
         stream_delete(socket, :templates, template)
         |> push_patch(to: "/dashboard/projects/#{socket.assigns.project.id}")}

      _ ->
        put_flash(socket, :error, "Failed to delete template with id: #{id}")
        {:noreply}
    end
  end

  @impl true
  def handle_event(
        "update_role",
        %{"role" => role, "member" => member_id} = _params,
        socket
      ) do
    case socket.assigns.project
         |> Ingest.Projects.update_project_members(
           Enum.find(socket.assigns.project.project_members, fn member ->
             member.id == member_id
           end),
           String.to_existing_atom(role)
         ) do
      {1, _n} ->
        {:noreply,
         socket
         |> put_flash(:info, "Succesfully Changed Role!")
         |> push_patch(to: ~p"/dashboard/projects/#{socket.assigns.project.id}")}

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed To Save Role!")
         |> push_patch(to: ~p"/dashboard/projects/#{socket.assigns.project.id}")}
    end
  end

  defp get_upload_count(request) do
    Uploads.uploads_for_request_count(request)
  end

  defp check_use(project, flavour) do
    if Ingest.Projects.request_count(project) > 0,
      do: "#{flavour} is in use are you sure you want to delete?",
      else: "Are you sure you want to delete?"
  end
end
