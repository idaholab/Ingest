defmodule IngestWeb.LiveComponents.TemplateForm do
  @moduledoc """
  Project Modal is the modal for creating/editing Projects. Contains all logic
  needed for the operation.
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@template_form}
        phx-change="validate"
        phx-target={@myself}
        id="template"
        phx-submit="save"
      >
        <div class="space-y-12">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">New Metadata Template</h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Create a new Metadata Template. A Metadata Template is a form designed to enforce metadata collection at the time of data uploads.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.label for="status-select">
                  Template Name
                </.label>
                <.input type="text" field={@template_form[:name]} />
              </div>

              <div class="col-span-full">
                <.label for="template-description">
                  Template Description
                </.label>
                <.input type="textarea" field={@template_form[:description]} />

                <p class="mt-3 text-sm leading-6 text-gray-600">
                  Write a few sentences about your template.
                </p>
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
  def update(%{template: template} = assigns, socket) do
    changeset = Ingest.Requests.change_template(template)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"template" => template_params}, socket) do
    changeset =
      socket.assigns.template
      |> Ingest.Requests.change_template(template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"template" => template_params}, socket) do
    save_template(socket, socket.assigns.live_action, template_params)
  end

  defp save_template(socket, :new, template_params) do
    case Map.put(template_params, "inserted_by", socket.assigns.current_user.id)
         |> Ingest.Requests.create_template() do
      {:ok, template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Template created successfully")
         |> redirect(to: ~p"/dashboard/templates/#{template.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :template_form, to_form(changeset))
  end
end
