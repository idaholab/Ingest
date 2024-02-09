defmodule IngestWeb.LiveComponents.DestinationForm do
  @moduledoc """
  Destination Form is the form for creating/editing Destinations
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@destination_form}
        phx-change="validate"
        phx-target={@myself}
        id="destination"
        phx-submit="save"
      >
        <div class="space-y-12">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">New Destination</h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Create a new Destination. A Destination is where your data will be placed, along with its metadata, after a user uploads it via Ingest.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.label for="status-select">
                  Destination Name
                </.label>
                <.input type="text" field={@destination_form[:name]} />
              </div>

              <div class="sm:col-span-4">
                <.label for="project-type">
                  Project Type
                </.label>
                <.input
                  type="select"
                  field={@destination_form[:type]}
                  options={[:internal, :s3, :azure]}
                />
              </div>
            </div>
          </div>

          <div
            :if={@type == "s3"}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">AWS S3 Credentials</h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Your AWS S3 credentials as well as the default location that Ingest should send that data to.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.inputs_for :let={config} field={@destination_form[:s3_config]}>
                  <.label for="status-select">
                    API Key
                  </.label>
                  <.input type="text" field={config[:api_key]} />

                  <.label for="status-select">
                    API Secret
                  </.label>
                  <.input type="text" field={config[:api_secret]} />

                  <.label for="status-select">
                    Bucket
                  </.label>
                  <.input type="text" field={config[:bucket]} />

                  <.label for="status-select">
                    Default Path
                  </.label>
                  <.input type="text" field={config[:path]} />
                </.inputs_for>
              </div>
            </div>
          </div>

          <div
            :if={@type == "azure"}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                Azure Data Lake Credentials
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Your Azure credentials as well as the default location that Ingest should send that data to.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.inputs_for :let={config} field={@destination_form[:azure_config]}>
                  <.label for="status-select">
                    Connection String
                  </.label>
                  <.input type="text" field={config[:connection_string]} />

                  <.label for="status-select">
                    Path
                  </.label>
                  <.input type="text" field={config[:path]} />
                </.inputs_for>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.button
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            phx-disable-with="Saving..."
          >
            Save
          </.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{destination: destination} = assigns, socket) do
    changeset = Ingest.Destinations.change_destination(destination)

    {:ok,
     socket
     |> assign(:type, Atom.to_string(destination.type))
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"destination" => destination_params}, socket) do
    changeset =
      socket.assigns.destination
      |> Ingest.Destinations.change_destination(destination_params)
      |> Map.put(:action, :validate)

    {:noreply,
     assign_form(socket |> assign(:type, Map.get(destination_params, "type")), changeset)}
  end

  def handle_event("save", %{"destination" => destination_params}, socket) do
    save_destination(socket, socket.assigns.live_action, destination_params)
  end

  defp save_destination(socket, :edit, destination_params) do
    case Ingest.Destinations.update_destination(socket.assigns.destination, destination_params) do
      {:ok, destination} ->
        notify_parent({:saved, destination})

        {:noreply,
         socket
         |> put_flash(:info, "Destination updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_destination(socket, :new, destination_params) do
    case Map.put(destination_params, "inserted_by", socket.assigns.current_user.id)
         |> Ingest.Destinations.create_destination() do
      {:ok, destination} ->
        notify_parent({:saved, destination})

        {:noreply,
         socket
         |> put_flash(:info, "Destination created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :destination_form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
