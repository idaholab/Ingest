defmodule IngestWeb.LiveComponents.TemplateFieldForm do
  @moduledoc """
  Project Modal is the modal for creating/editing Projects. Contains all logic
  needed for the operation.
  """
  alias Ingest.Requests.TemplateField
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@field_form}
        phx-change="validate"
        phx-target={@myself}
        id="field"
        phx-submit="save"
      >
        <div class="space-y-12">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">New Field</h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Start a new field. You will have a chance to add more options and modify after this screen.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.label for="status-select">
                  Field Type
                </.label>
                <.input
                  type="select"
                  field={@field_form[:type]}
                  id="label"
                  options={[
                    Dropdown: :select,
                    Text: :text,
                    Number: :number,
                    "Large Text Area": :textarea,
                    Checkbox: :checkbox,
                    Date: :date,
                    "Branch Choice Dropdown": :branch
                  ]}
                />

                <p class="mt-3 text-sm leading-6 text-gray-600">
                  What type of field should be presented to the user
                </p>
              </div>

              <div class="col-span-full">
                <.label for="template-description">
                  Label
                </.label>
                <.input type="textarea" field={@field_form[:label]} />

                <p class="mt-3 text-sm leading-6 text-gray-600">
                  The label for your field.
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
  def update(assigns, socket) do
    changeset =
      Ingest.Requests.change_template_field(
        %Ingest.Requests.TemplateField{},
        %{}
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"template_field" => field_params}, socket) do
    changeset =
      %TemplateField{}
      |> Ingest.Requests.change_template_field(field_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"template_field" => field_params}, socket) do
    case Ingest.Requests.update_template(socket.assigns.template, %{
           fields:
             Enum.map(socket.assigns.fields, fn f -> Map.from_struct(f) end) ++ [field_params]
         }) do
      {:ok, _} ->
        {:noreply,
         socket
         |> redirect(to: ~p"/dashboard/templates/#{socket.assigns.template.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :field_form, to_form(changeset))
  end
end
