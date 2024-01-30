defmodule IngestWeb.TemplateBuilderLive do
  use IngestWeb, :live_view

  alias Ingest.Requests

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
        <h3 class="text-base font-semibold leading-6 text-gray-900">Form Builder</h3>
      </div>
    </div>

    <div class="flex flex-row">
      <div class="basis-1/3">
        <ul
          id="fields"
          role="list"
          class="divide-y divide-gray-100"
          phx-update="stream"
          phx-hook="FormBuilderFields"
          id="form-builder-field"
        >
          <li
            :for={field <- @fields}
            id={field.id}
            phx-click={JS.patch(~p"/dashboard/templates/#{@template.id}/fields/#{field.id}")}
            class={active(field.id, @field)}
            data-id={field.id}
          >
            <div>
              <div class="min-w-0 px-2 flex flex-row drag-ghost:opacity-0">
                <div class="items-start gap-x-3 basis-2/3 pr-10 ">
                  <p class="text-sm font-semibold leading-6 text-gray-900"><%= field.label %></p>
                  <p class="whitespace-nowrap text-sm col-span-2">
                    <%= field.type %>
                  </p>
                </div>
                <div>
                  <p class="whitespace-nowrap items-right">
                    <span
                      :if={field.required}
                      class="inline-flex items-center rounded-md bg-red-100 px-2 py-1 text-xs font-medium text-red-700"
                    >
                      Required
                    </span>
                    <span
                      :if={!field.required}
                      class="inline-flex items-center rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700"
                    >
                      Optional
                    </span>
                  </p>
                </div>
              </div>
              <div class="py-2">
                <span class="inline-flex items-center rounded-md bg-blue-100 px-2 py-1 text-xs font-medium text-blue-700">
                  all
                </span>

                <span
                  :for={type <- field.file_extensions}
                  class="inline-flex items-center rounded-md bg-yellow-100 px-2 py-1 text-xs font-medium text-yellow-700 mr-1"
                >
                  <%= type %>
                </span>
              </div>
            </div>
          </li>
        </ul>
      </div>

      <div :if={@field} class=" bg-gray-800 p-8 basis-2/3">
        <.form for={@field_form} phx-change="validate" id="field" phx-submit="save">
          <div class="space-y-12">
            <div class="border-b border-white/10 pb-12">
              <p class="mt-1 text-md leading-6 text-gray-400">
                Choose your field type and options.
              </p>

              <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div class="sm:col-span-3">
                  <label for="country" class="block text-sm font-medium leading-6 text-white">
                    Type
                  </label>
                  <div class="mt-2">
                    <.input
                      type="select"
                      field={@field_form[:type]}
                      id="label"
                      options={[:select, :text, :number, :textarea, :checkbox, :date]}
                    />
                  </div>
                </div>
              </div>

              <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div class="sm:col-span-4">
                  <label for="username" class="block text-sm font-medium leading-6 text-white">
                    Label
                  </label>
                  <div class="mt-2">
                    <.input type="text" field={@field_form[:label]} />
                  </div>
                </div>

                <div class="col-span-full">
                  <label for="about" class="block text-sm font-medium leading-6 text-white">
                    Help Text
                  </label>
                  <div class="mt-2">
                    <.input type="textarea" field={@field_form[:help_text]} />
                  </div>

                  <p class="mt-3 text-sm leading-6 text-gray-400">
                    Optional: write a few setences to describe the information you're requesting.
                  </p>
                </div>
              </div>

              <div class="sm:col-span-4 py-5">
                <label for="username" class="block text-sm font-medium leading-6 text-white">
                  File Extensions
                </label>
                <div class="mt-2">
                  <.input type="combobox" field={@field_form[:file_extensions]} />
                </div>
                <p class="mt-3 text-sm leading-6 text-gray-400">
                  Comma-seperated values. Example: .csv,.pdf,.html - Leave blank for all file types
                </p>
              </div>

              <fieldset>
                <div class="sm:col-span-4 py-3">
                  <label for="username" class="block text-sm font-medium leading-6 text-white">
                    Required
                  </label>
                  <div class="mt-2">
                    <.input type="checkbox" field={@field_form[:required]} />
                  </div>
                  <p class="mt-3 text-sm leading-6 text-gray-400">
                    Whether or not a user is required to fill the field before submitting.
                  </p>
                </div>
              </fieldset>
            </div>
          </div>

          <div class="mt-6 flex items-center justify-end gap-x-6">
            <button type="button" class="text-sm font-semibold leading-6 text-white">Cancel</button>
            <button
              type="submit"
              phx-disable-with="Saving..."
              class="rounded-md bg-indigo-500 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
            >
              Save
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    template = Requests.get_template!(id)

    {:ok,
     socket
     |> assign(:template, template)
     |> assign(:fields, template.fields)
     |> assign(:section, "templates"), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"field_id" => field_id}, _uri, socket) do
    template = Requests.get_template!(socket.assigns.template.id)
    field = Enum.find(template.fields, fn field -> field.id == field_id end)

    {:noreply,
     socket
     |> assign(:field, field)
     |> assign(:template, template)
     |> assign(:field_form, to_form(Requests.change_template_field(field)))}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket |> assign(:field, nil)}
  end

  @impl true
  def handle_event("reposition", params, socket) do
    %{"id" => id, "new" => new, "old" => old} = params
    # Put your logic here to deal with the changes to the list order
    # and persist the data
    field = Enum.find(socket.assigns.fields, fn f -> f.id == id end)

    list =
      List.delete_at(socket.assigns.fields, old)
      |> List.insert_at(new, field)
      |> Enum.map(fn f -> Map.from_struct(f) end)

    Requests.update_template(socket.assigns.template, %{fields: list})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"template_field" => field_params}, socket) do
    %{"file_extensions" => file_extensions} = field_params

    field_params =
      field_params |> Map.replace("file_extensions", file_extensions |> String.split(","))

    changeset =
      socket.assigns.field
      |> Ingest.Requests.change_template_field(field_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:field_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"template_field" => field_params}, socket) do
    %{"file_extensions" => file_extensions} = field_params

    field_params =
      field_params |> Map.replace("file_extensions", file_extensions |> String.split(","))

    fields =
      Enum.map(socket.assigns.fields, fn f ->
        field = Map.from_struct(f)

        if field.id == socket.assigns.field.id do
          field_params
          |> Map.put("id", socket.assigns.field.id)
        else
          field
        end
      end)

    case Ingest.Requests.update_template(socket.assigns.template, %{fields: fields}) do
      {:ok, _template} ->
        {:noreply,
         socket
         |> push_patch(
           to:
             ~p"/dashboard/templates/#{socket.assigns.template.id}/fields/#{socket.assigns.field.id}"
         )
         |> put_flash(:info, "Template fields saved successfully")}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply, socket |> assign(:field_form, to_form(socket.assigns.field))}
    end
  end

  defp active(current, field) do
    if field && current == field.id do
      "flex items-center justify-between gap-x-6 py-5 active active:bg-green-100 bg-green-100 px-1 cursor-pointer drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
    else
      "flex items-center justify-between gap-x-6 py-5 px-1 cursor-pointer drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
    end
  end
end
