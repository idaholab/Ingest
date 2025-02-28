defmodule IngestWeb.TemplateBuilderLive do
require Logger
  use IngestWeb, :live_view
  alias Ingest.Requests

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-base font-semibold leading-6 text-gray-900">{@template.name}</h1>
          <p class="mt-2 text-sm text-gray-700">
            {@template.description}
          </p>
        </div>
        <.link
          :if={@template.inserted_by == @current_user.id}
          navigate={~p"/dashboard/templates/#{@template.id}/share"}
        >
          <.button class="bg-primary">Share</.button>
        </.link>
      </div>
      <div class="mt-5 border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
        <h3 class="text-base font-semibold leading-6 text-gray-900">Form Builder</h3>
      </div>
    </div>
    <!-- Start field wrap -->
    <div class="flex flex-row">
      <!-- Start field list -->
      <div class="basis-1/3">
        <.link
          patch={~p"/dashboard/templates/#{@template.id}/new"}
          type="button"
          class="relative block w-full mt-5 rounded-lg border-2 border-dashed border-gray-300 p-3 text-center hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
        >
          <span class="mt-2 block text-sm font-semibold text-gray-900">Add Field</span>
        </.link>
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
            data-tip="hello"
            data-id={field.id}
          >
            <div>
              <div class="min-w-0 px-2 flex flex-row drag-ghost:opacity-0 ">
                <div class="items-start gap-x-3 basis-2/3 pr-10 ">
                  <p class="text-sm font-semibold leading-6 text-gray-900">{field.label}</p>
                  <p class="whitespace-nowrap text-sm col-span-2">
                    {friendly_field(field.type)}
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
              <div :if={field.file_extensions} class="py-2">
                <span
                  :if={field.file_extensions == []}
                  class="inline-flex items-center rounded-md bg-blue-100 px-2 py-1 text-xs font-medium text-blue-700"
                >
                  all
                </span>

                <span
                  :for={type <- field.file_extensions}
                  class="inline-flex items-center rounded-md bg-yellow-100 px-2 py-1 text-xs font-medium text-yellow-700 mr-1"
                >
                  {type}
                </span>
              </div>
              <div class="items-center tooltip tooltip-bottom" data-tip="Drag to Order">
                <.icon name="hero-arrows-up-down" />
              </div>
            </div>
            <div>
              <button phx-click="delete_field" phx-value-field={field.id}>
                <.icon name="hero-trash" />
              </button>
            </div>
          </li>
        </ul>
      </div>
      <!-- end field list -->
      <!-- Start field creator -->
      <div :if={!@field} class="bg-gray-800 p-8 basis-2/3 h-screen ml-10">
        <div class="text-center">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path
              vector-effect="non-scaling-stroke"
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 13h6m-3-3v6m-9 1V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-semibold text-white">No field selected</h3>
          <p class="mt-1 text-sm text-white">Get started by adding a new field on the left.</p>
        </div>
      </div>

      <div :if={@field} class=" bg-gray-800 p-8 basis-2/3 h-screen-full ml-10">
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
                      options={[
                        Text: :text,
                        Dropdown: :select,
                        Number: :number,
                        "Large Text Area": :textarea,
                        Checkbox: :checkbox,
                        Date: :date,
                        "Branching Dropdown": :branch
                      ]}
                    />
                  </div>
                  <p :if={@field.type == :branch} class="text-gray-400 text-sm pt-2">
                    A branching dropdown allows you to setup a dynamically appearing metadata template depending on user choice
                  </p>
                </div>
              </div>
              <!-- SELECT/DROPDOWN OPTIONS -->
              <div
                :if={@field.type == :select}
                class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6"
              >
                <ul
                  :if={@field.type == :select && @field.select_options}
                  role="list"
                  class="divide-y divide-white/5 sm:col-span-4"
                >
                  <li
                    :for={option <- @field.select_options}
                    id={option}
                    class="relative flex items-center space-x-4 py-4"
                  >
                    <div class="min-w-0 flex-auto">
                      <div class="flex items-center gap-x-3">
                        <h2 class="min-w-0 text-sm font-semibold leading-6 text-white">
                          <a href="#" class="flex gap-x-2">
                            <span class="truncate">{option}</span>
                          </a>
                        </h2>
                      </div>
                    </div>

                    <.link phx-click="remove_option" phx-value-option={option}>
                      <.icon name="hero-x-mark" class="h-5 w-5 flex-none text-gray-400" />
                    </.link>
                  </li>
                </ul>
                <div :if={@field.type == :select} class="sm:col-span-4">
                  <.input type="text" field={@select_form[:option]} id="options" />

                  <button
                    name="save"
                    phx-disable-with="Saving..."
                    value="option"
                    class="mt-3 rounded-md bg-indigo-500 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
                  >
                    Add Option
                  </button>
                </div>
              </div>
              <!-- BRANCH OPTIONS -->
              <div class="mt-5 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <ul
                  :if={@field.type == :branch && @field.branch_options != []}
                  role="list"
                  class="divide-y divide-white/5 sm:col-span-4"
                >
                  <li
                    :for={%{"name" => name, "template" => template} <- @field.branch_options}
                    id={template}
                    class="relative flex items-center space-x-4 py-4"
                  >
                    <div class="min-w-0 flex-auto">
                      <div class="flex items-center gap-x-3">
                        <h2 class="min-w-0 text-sm font-semibold leading-6 text-white">
                          <a href="#" class="flex gap-x-2">
                            <span class="truncate">{name} --></span>
                            <span class="truncate">
                              {Ingest.Requests.get_template!(template).name}
                            </span>
                          </a>
                        </h2>
                      </div>
                    </div>

                    <.link
                      phx-click="remove_branch_option"
                      phx-value-name={name}
                      phx-value-template={template}
                    >
                      <.icon name="hero-x-mark" class="h-5 w-5 flex-none text-gray-400" />
                    </.link>
                  </li>
                </ul>
                <div :if={@field.type == :branch} class="sm:col-span-4">
                  <span
                    phx-click={
                      JS.patch(
                        ~p"/dashboard/templates/#{@template.id}/fields/#{@field.id}/search_templates"
                      )
                    }
                    class="cursor-pointer mt-3 rounded-md bg-indigo-500 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
                  >
                    Add Branching Option
                  </span>
                </div>
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
                    <b>Markdown is supported</b>
                  </p>
                </div>
              </div>

              <div class="sm:col-span-4 py-5">
                <label for="username" class="block text-sm font-medium leading-6 text-white">
                  File Extensions
                </label>
                <div class="mt-2">
                  <.input type="text" field={@field_form[:file_extensions]} />
                </div>
                <p class="mt-3 text-sm leading-6 text-gray-400">
                  Show this field only for the provided file extensions.
                </p>
                <p class="mt-3 text-sm leading-6 text-gray-400">
                  Comma-seperated values. Example: .csv,.pdf,.html - Leave blank for all file types
                </p>
              </div>
            </div>
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
            <%= if @field_form[:required].value in ["true", true] do %>
              <div id="naming_convention" class="sm:col-span-4 py-3">
                <label for="name_field" class="block text-sm font-medium leading-6 text-white">
                  Used In Naming Convention
                </label>
                <div class="mt-2">
                  <.input type="checkbox" field={@field_form[:name_field]} />
                </div>
                <p class="mt-3 text-sm leading-6 text-gray-400">
                  Whether or not this field will be used in the naming convention for data uploads.
                </p>
              </div>
            <% end %>
          </fieldset>

          <div class="mt-6 flex items-center justify-end gap-x-6">
            <button type="button" class="text-sm font-semibold leading-6 text-white">Cancel</button>
            <button
              name="save"
              value="full"
              type="submit"
              phx-disable-with="Saving..."
              class="rounded-md bg-indigo-500 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
            >
              Save
            </button>
          </div>
        </.form>
      </div>

      <.modal
        :if={@live_action in [:search_templates]}
        id="template-search_modal"
        show
        on_cancel={JS.patch(@on_cancel)}
      >
        <.live_component
          live_action={@live_action}
          module={IngestWeb.LiveComponents.BranchTemplateSearch}
          id="template-search-modal-component"
          current_user={@current_user}
          patch={@on_cancel}
        />
      </.modal>

      <.modal
        :if={@live_action in [:new]}
        id="template_field_modal"
        show
        on_cancel={JS.patch(@on_cancel)}
      >
        <.live_component
          live_action={@live_action}
          template={@template}
          fields={@fields}
          module={IngestWeb.LiveComponents.TemplateFieldForm}
          id="template-field-modal-component"
          current_user={@current_user}
        />
      </.modal>

      <.modal
        :if={@live_action in [:share]}
        id="template_share_modal"
        show
        on_cancel={JS.patch(@on_cancel)}
      >
        <.live_component
          live_action={@live_action}
          template={@template}
          module={IngestWeb.LiveComponents.ShareTemplateForm}
          id="template-share-modal-component"
          current_user={@current_user}
        />
      </.modal>
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
     |> assign(:on_cancel, ~p"/dashboard/templates/#{template.id}")
     |> assign(:section, "templates"), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"field_id" => field_id}, _uri, socket) do
    template = Requests.get_template!(socket.assigns.template.id)
    field = Enum.find(template.fields, fn field -> field.id == field_id end)
    # Fires when you select anew field.

    {:noreply,
     socket
     |> assign(:field, field)
     |> assign(:template, template)
     |> assign(:on_cancel, ~p"/dashboard/templates/#{template.id}/fields/#{field.id}")
     |> assign(:select_form, to_form(%{option: nil}))
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
  def handle_event("delete_field", %{"field" => id}, socket) do
    Requests.update_template(socket.assigns.template, %{
      fields:
        Enum.filter(socket.assigns.fields, fn f -> f.id != id end)
        |> Enum.map(fn f -> Map.from_struct(f) end)
    })

    {:noreply,
     socket
     |> push_navigate(to: ~p"/dashboard/templates/#{socket.assigns.template.id}")}
  end

  @impl true
  def handle_event("validate", %{"template_field" => field_params}, socket) do
    %{"file_extensions" => file_extensions, "required" => required, "type" => type} = field_params

    is_required = required in ["true", true]

    field_params =
      field_params
      |> Map.replace("file_extensions", String.split(file_extensions, ","))
      |> Map.put(
        "name_field",
        case is_required do
          true -> field_params["name_field"]
          false -> false
        end
      )

    changeset =
      socket.assigns.field
      |> Ingest.Requests.change_template_field(field_params)
      |> Map.put(:action, :validate)

    if String.to_existing_atom(type) != socket.assigns.field.type do
      {:noreply, socket |> save_field(field_params)}
    else
      {:noreply, socket |> assign(:field_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event(
        "save",
        %{"option" => option, "save" => "option", "template_field" => field_params},
        socket
      ) do
    %{"file_extensions" => file_extensions} = field_params

    field_params =
      field_params
      |> Map.replace("file_extensions", file_extensions |> String.split(","))
      |> Map.put("select_options", socket.assigns.field.select_options ++ [option])

    {:noreply, socket |> save_field(field_params)}
  end

  @impl true
  def handle_event("save", %{"template_field" => field_params}, socket) do
    %{"file_extensions" => file_extensions} = field_params

    field_params =
      field_params |> Map.replace("file_extensions", file_extensions |> String.split(","))

    {:noreply, socket |> save_field(field_params)}
  end

  @impl true
  def handle_event("add_option", _params, socket) do
    field =
      Map.from_struct(socket.assigns.field)
      |> Map.put("select_options", ["" | socket.assigns.field.select_options])

    {:noreply, socket |> save_field(field)}
  end

  @impl true
  def handle_event("remove_option", %{"option" => option}, socket) do
    field =
      %{"id" => socket.assigns.field.id}
      |> Map.put(
        "select_options",
        Enum.filter(socket.assigns.field.select_options, fn o -> o != option end)
      )

    {:noreply, socket |> save_field(field)}
  end

  @impl true
  def handle_event("remove_branch_option", %{"name" => name, "template" => template}, socket) do
    field =
      %{"id" => socket.assigns.field.id}
      |> Map.put(
        "branch_options",
        Enum.filter(socket.assigns.field.branch_options, fn o ->
          o != %{"name" => name, "template" => template}
        end)
      )

    {:noreply, socket |> save_field(field)}
  end

  @impl true
  def handle_info({_child, {:branch_added, %{name: name, template: template}}}, socket) do
    field =
      Map.from_struct(socket.assigns.field)
      |> Map.put(:branch_options, [
        %{name: name, template: template.id} | socket.assigns.field.branch_options
      ])

    {:noreply,
     socket
     |> save_field_atoms(field)}
  end

  defp active(current, field) do
    if field && current == field.id do
      "flex items-center justify-between gap-x-6 py-5 active active:bg-indigo-100 bg-indigo-100 px-1 cursor-pointer drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0 "
    else
      "flex items-center justify-between gap-x-6 py-5 px-1 cursor-pointer drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
    end
  end

  defp save_field(socket, field_params) do

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
        socket
        |> push_navigate(
          to:
            ~p"/dashboard/templates/#{socket.assigns.template.id}/fields/#{socket.assigns.field.id}"
        )
        |> put_flash(:info, "Template fields saved successfully")

      {:error, %Ecto.Changeset{} = _changeset} ->
        socket |> assign(:field_form, to_form(socket.assigns.field))
    end
  end

  defp save_field_atoms(socket, field_params) do

    fields =
      Enum.map(socket.assigns.fields, fn f ->
        field = Map.from_struct(f)

        if field.id == socket.assigns.field.id do
          field_params
          |> Map.put(:id, socket.assigns.field.id)
        else
          field
        end
      end)

    case Ingest.Requests.update_template(socket.assigns.template, %{fields: fields}) do
      {:ok, _template} ->
        socket
        |> push_navigate(
          to:
            ~p"/dashboard/templates/#{socket.assigns.template.id}/fields/#{socket.assigns.field.id}"
        )
        |> put_flash(:info, "Template fields saved successfully")

      {:error, %Ecto.Changeset{} = _changeset} ->
        socket |> assign(:field_form, to_form(socket.assigns.field))
    end
  end

  defp friendly_field(field) do
    case field do
      :select -> "Dropdown"
      :text -> "Text"
      :number -> "Number"
      :textarea -> "Large Text Area"
      :checkbox -> "Checkbox"
      :date -> "Date Picker"
      :branch -> "Branching Dropdown"
    end
  end
end
