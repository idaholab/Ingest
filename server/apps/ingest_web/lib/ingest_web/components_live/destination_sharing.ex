defmodule IngestWeb.LiveComponents.DestinationSharing do
  @moduledoc """
  This is the LiveComponent for managing the sharing of destinations with other people.
  """

  use IngestWeb, :live_component
  alias Ingest.Destinations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p>
        This page lists all the people, projects, or data requests that have access to this destination, as well as thier permissions. Note that a user may appear multiple times on this page, if they are the owner of the request, or project, that has access to the destination.
      </p>
      <.table id="sharing" rows={@members}>
        <:col :let={member} label="User">{member.user.email}</:col>
        <:col :let={member} label="Project Name">
          {if member.project, do: member.project.name, else: "N/A"}
        </:col>
        <:col :let={member} label="Request Name">
          {if member.request, do: member.request.name, else: "N/A"}
        </:col>

        <:col :let={member} label="Status">
          <.form
            for={}
            phx-change="update_status"
            phx-target={@myself}
            phx-value-member={member.id}
            phx-value-email={member.user.email}
          >
            <.input
              name="status"
              type="select"
              value={member.status}
              prompt="Select one"
              options={[Approved: :accepted, "Pending Approval": :pending, Rejected: :rejected]}
            />
          </.form>
        </:col>
        <:col :let={member} label="Type">
          <.form
            for={}
            phx-change="update_role"
            phx-target={@myself}
            phx-value-member={member.id}
            phx-value-email={member.user.email}
          >
            <.input
              name="role"
              type="select"
              value={member.role}
              prompt="Select one"
              options={[Uploader: :uploader, Manager: :manager]}
            />
          </.form>
        </:col>

        <:action :let={member}>
          <.link
            :if={
              Bodyguard.permit?(
                Ingest.Destinations.Destination,
                :update_destination,
                @current_user,
                @destination
              ) && (member.project_id || member.request_id)
            }
            class="text-indigo-600 hover:text-indigo-900"
            patch={~p"/dashboard/destinations/#{@destination}/sharing/#{member}"}
          >
            Configure
          </.link>
        </:action>

        <:action :let={member}>
          <.link
            :if={
              Bodyguard.permit?(
                Ingest.Destinations.Destination,
                :update_destination,
                @current_user,
                @destination
              )
            }
            phx-target={@myself}
            class="text-red-600 hover:text-red-900"
            phx-click={JS.push("revoke_access", value: %{id: member.id})}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.simple_form for={@invite_form} phx-submit="save" phx-target={@myself}>
        <.input
          field={@invite_form[:email]}
          type="email"
          class="shadow-sm text-black text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full p-2.5"
          placeholder="name@deeplynx.com"
          required
          label="Invitee's Email"
        />
        <button class="flex-shrink-0 rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          Send Invite
        </button>
      </.simple_form>
      <p class="mt-10">
        Directly invited members are typically co-managers of the destination, and are allowed to make changes to things like its configuration and its access.
      </p>
    </div>
    """
  end

  @impl true
  def update(%{destination: destination} = assigns, socket) do
    {:ok,
     socket
     |> assign(:destination, destination)
     |> assign(:invite_form, to_form(%{"email" => ""}))
     |> assign(:members, Destinations.list_destination_members(destination))
     |> assign(assigns)}
  end

  @impl true
  def handle_event("save", %{"email" => email}, socket) do
    case Ingest.Destinations.add_user_to_destination_by_email(socket.assigns.destination, email) do
      {:ok, _n} ->
        {:noreply,
         socket
         |> put_flash(:info, "Succesfully Invited User!")
         |> push_patch(to: ~p"/dashboard/destinations")}

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed To Invite User!")
         |> push_patch(to: ~p"/dashboard/destinations")}
    end
  end

  @impl true
  def handle_event(
        "update_role",
        %{"role" => role, "member" => member_id} = _params,
        socket
      ) do
    {id, _rest} = Integer.parse(member_id, 10)

    case Ingest.Destinations.update_destination_members_role(
           Enum.find(socket.assigns.members, fn member ->
             member.id == id
           end),
           String.to_existing_atom(role)
         ) do
      {1, _n} ->
        {:noreply,
         socket
         |> put_flash(:info, "Succesfully Changed Role!")
         |> push_patch(to: ~p"/dashboard/destinations/#{socket.assigns.destination.id}/sharing")}

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed To Save Role!")
         |> push_patch(to: ~p"/dashboard/destinations/#{socket.assigns.destination.id}/sharing")}
    end
  end

  @impl true
  def handle_event(
        "update_status",
        %{"status" => status, "member" => member_id} = _params,
        socket
      ) do
    {id, _rest} = Integer.parse(member_id, 10)

    member =
      Enum.find(socket.assigns.members, fn member ->
        member.id == id
      end)

    status = String.to_existing_atom(status)

    case Ingest.Destinations.update_destination_members_status(
           member,
           status
         ) do
      {1, _n} ->
        # if we've updated we need to either remove or add a record
        propogate_status(status, member)

        {:noreply,
         socket
         |> put_flash(:info, "Succesfully Changed Status!")
         |> push_patch(to: ~p"/dashboard/destinations/#{socket.assigns.destination.id}/sharing")}

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed To Save Status!")
         |> push_patch(to: ~p"/dashboard/destinations/#{socket.assigns.destination.id}/sharing")}
    end
  end

  @impl true
  def handle_event(
        "revoke_access",
        %{"id" => member_id} = _params,
        socket
      ) do
    case Ingest.Destinations.remove_destination_members(member_id) do
      {1, _n} ->
        {:noreply,
         socket
         |> put_flash(:info, "Succesfully Revoked Access!")
         |> push_patch(to: ~p"/dashboard/destinations/#{socket.assigns.destination.id}/sharing")}

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to Revoke Access!")
         |> push_patch(to: ~p"/dashboard/destinations/#{socket.assigns.destination.id}/sharing")}
    end
  end

  # if accepted we can add the record
  defp propogate_status(:accepted, member) do
    cond do
      member.request_id ->
        Ingest.Requests.add_request_destination(
          Ingest.Requests.get_request!(member.request_id),
          Ingest.Destinations.get_destination!(member.destination_id)
        )

      member.project_id ->
        Ingest.Projects.add_destination(
          Ingest.Projects.get_project!(member.project_id),
          Ingest.Destinations.get_destination!(member.destination_id)
        )
    end
  end

  # everything else removed
  defp propogate_status(_status, member) do
    cond do
      member.request_id ->
        Ingest.Requests.remove_destination(
          Ingest.Requests.get_request!(member.request_id),
          Ingest.Destinations.get_destination!(member.destination_id)
        )

      member.project_id ->
        Ingest.Projects.remove_destination(
          Ingest.Projects.get_project!(member.project_id),
          Ingest.Destinations.get_destination!(member.destination_id)
        )
    end
  end
end
