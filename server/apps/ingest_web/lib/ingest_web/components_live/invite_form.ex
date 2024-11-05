defmodule IngestWeb.LiveComponents.InviteForm do
  @moduledoc """
  InviteModal is the modal for Inviting Users to Data Requests. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
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
    case Ingest.Requests.RequestNotifier.notify_data_request_invite(email, socket.assigns.request) do
      {:ok, _n} ->
        case Ingest.Requests.invite_user_by_email(socket.assigns.request, email) do
          {:ok, _n} ->
            {:noreply,
             socket
             |> put_flash(:info, "Succesfully Invited User!")
             |> redirect(to: ~p"/dashboard/requests/#{socket.assigns.request.id}")}

          {:error, _e} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed To Invite User!")
             |> redirect(to: ~p"/dashboard/requests/#{socket.assigns.request.id}")}
        end

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed To Send Email to User!")
         |> redirect(to: ~p"/dashboard/requests/#{socket.assigns.request.id}")}
    end
  end
end
