defmodule IngestWeb.LiveComponents.RegisterClientForm do
  @moduledoc """
  This form handles registering new clients, typically called from the client UI or as part of an automatic
  detection service.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@client_form}
        phx-change="validate"
        phx-target={@myself}
        id="client"
        phx-submit="save"
      >
        <div class="space-y-12">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">New Client</h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Register a new Ingest desktop client for future uploads.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.label for="device-id">
                  Device ID
                </.label>
                <.input
                  type="text"
                  field={@client_form[:id]}
                  {[disabled: "disabled", readonly: "readonly"]}
                />
                <p class="text-sm">
                  Please verify this is the same ID as show in your client. Check that by either checking the dropdown in the system tray or by navigating
                  <a href="http://localhost:8097">here.</a>
                </p>
              </div>

              <div class="sm:col-span-4">
                <.label for="friendly-name">
                  Friendly Name
                </.label>
                <.input type="text" field={@client_form[:name]} />
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.button
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            phx-disable-with="Saving..."
          >
            Register
          </.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{client: client} = assigns, socket) do
    changeset = Ingest.Destinations.change_client(client)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"client" => client_params}, socket) do
    changeset =
      socket.assigns.client
      |> Ingest.Destinations.change_client(client_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"client" => client_params}, socket) do
    save_client(socket, client_params)
  end

  defp save_client(socket, client_params) do
    token =
      Phoenix.Token.sign(socket, "client_auth", %{
        _id: socket.assigns.current_user.id,
        client_id: socket.assigns.client_form.id
      })

    case Map.put(client_params, "owner_id", socket.assigns.current_user.id)
         |> Map.put(
           "token",
           token
         )
         |> Ingest.Destinations.create_client() do
      {:ok, _client} ->
        {:noreply,
         socket
         |> put_flash(:info, "Client registered successfully")
         # redirect out to the client again with the newly minted and saved token for registration
         |> redirect(external: "http://localhost:8097/callback?token=#{token}")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(
      socket,
      :client_form,
      to_form(changeset |> Ecto.Changeset.change(%{id: socket.assigns.client.id}))
    )
  end
end
