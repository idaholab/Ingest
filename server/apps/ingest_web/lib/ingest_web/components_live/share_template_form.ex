defmodule IngestWeb.LiveComponents.ShareTemplateForm do
  @moduledoc """
  InviteModal is the modal for Inviting Users to Data Requests. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <dul role="list" class="divide-y divide-gray-100">
        <%= for member <- @template.template_members do %>
          <li class="flex items-center justify-between gap-x-6 py-5">
            <div class="flex min-w-0 gap-x-4">
              <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-gray-500">
                <span class="font-medium leading-none text-white">
                  {if member.name do
                    String.slice(member.name, 0..1) |> String.upcase()
                  end}
                </span>
              </span>
              <div class="min-w-0 flex-auto">
                <p class="text-sm font-semibold leading-6 text-gray-900">{member.name}</p>
                <p class="mt-1 truncate text-xs leading-5 text-gray-500">
                  {member.email}
                </p>
              </div>
            </div>
            <.form
              for={}
              phx-change="update_role"
              phx-target={@myself}
              phx-value-member={member.id}
              phx-value-email={member.email}
            >
              <.input
                name="role"
                type="select"
                value={member.roles}
                prompt="Select one"
                options={[:member, :manager]}
              />
            </.form>
            <div>
              <span
                :if={
                  Bodyguard.permit?(
                    Ingest.Requests.Template,
                    :update_template,
                    @current_user,
                    @template
                  ) || member.id == @current_user.id
                }
                data-confirm="Are you sure?"
                phx-click="remove_member"
                phx-value-member={member.id}
                phx-value-project={@template.id}
                class="inline-flex items-center rounded-md bg-red-50 px-2 py-1 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/10 cursor-pointer"
              >
                Remove
              </span>
            </div>
          </li>
        <% end %>
      </dul>
      <.simple_form for={@invite_form} phx-submit="save" phx-target={@myself}>
        <.input
          field={@invite_form[:email]}
          type="email"
          class="shadow-sm text-black text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full p-2.5"
          placeholder="name@deeplynx.com"
          required
          label="Invitee's Email"
        />
        <div class="flex flex-row-reverse">
          <button class="flex-shrink-0 rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
            Send Invite
          </button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:invite_form, to_form(%{"email" => ""}))
     |> assign(assigns)}
  end

  @impl true
  def handle_event("save", %{"email" => email}, socket) do
    case Ingest.Requests.add_user_to_template_by_email(socket.assigns.template, email) do
      {:ok, _n} ->
        {:noreply,
         socket
         |> put_flash(:info, "Succesfully Invited User!")
         |> push_patch(to: ~p"/dashboard/templates/#{socket.assigns.template.id}")}

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed To Invite User!")
         |> push_patch(to: ~p"/dashboard/templates/#{socket.assigns.template.id}")}
    end
  end

  @impl true
  def handle_event(
        "update_role",
        %{"role" => role, "member" => member_id} = _params,
        socket
      ) do
    case socket.assigns.template
         |> Ingest.Requests.update_template_members(
           Enum.find(socket.assigns.template.template_members, fn member ->
             member.id == member_id
           end),
           String.to_existing_atom(role)
         ) do
      {1, _n} ->
        {:noreply,
         socket
         |> put_flash(:info, "Succesfully Changed Role!")
         |> push_patch(to: ~p"/dashboard/templates/#{socket.assigns.template.id}/share")}

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed To Save Role!")
         |> push_patch(to: ~p"/dashboard/templates/#{socket.assigns.template.id}/share")}
    end
  end
end
