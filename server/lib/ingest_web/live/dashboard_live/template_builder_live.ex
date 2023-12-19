defmodule IngestWeb.TemplateBuilderLive do
  use IngestWeb, :live_view

  alias Ingest.Requests

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
        <h3 class="text-base font-semibold leading-6 text-gray-900">Form Builder</h3>
        <div class="mt-3 flex sm:ml-4 sm:mt-0">
          <button
            type="button"
            class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Back
          </button>
          <button
            type="button"
            class="ml-3 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Save
          </button>
        </div>
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
                    <span class="inline-flex items-center rounded-md bg-indigo-100 px-2 py-1 text-xs font-medium text-indigo-700">
                      Per File
                    </span>
                    |
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
        <form>
          <div class="space-y-12">
            <div class="border-b border-white/10 pb-12">
              <p class="mt-1 text-md leading-6 text-gray-400">
                Choose your field type and options.
              </p>

              <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div class="sm:col-span-4">
                  <label for="username" class="block text-sm font-medium leading-6 text-white">
                    Label
                  </label>
                  <div class="mt-2">
                    <.input type="text" @dark={true} field={@field_form[:label]} />
                  </div>
                </div>

                <div class="col-span-full">
                  <label for="about" class="block text-sm font-medium leading-6 text-white">
                    Help Text
                  </label>
                  <div class="mt-2">
                    <.input type="textarea" @dark={true} field={@field_form[:help_text]} />
                  </div>

                  <p class="mt-3 text-sm leading-6 text-gray-400">
                    Optional: write a few setences to describe the information you're requesting.
                  </p>
                </div>
              </div>

              <div class="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div class="sm:col-span-3">
                  <label for="country" class="block text-sm font-medium leading-6 text-white">
                    Type
                  </label>
                  <div class="mt-2">
                    <.input
                      type="select"
                      @dark={true}
                      field={@field_form[:type]}
                      id="label"
                      options={[:select, :text, :number, :textarea, :checkbox, :date]}
                    />
                  </div>
                </div>
              </div>

              <div class="sm:col-span-4 py-5">
                <label for="username" class="block text-sm font-medium leading-6 text-white">
                  File Extensions
                </label>
                <div class="mt-2">
                  <.input type="combobox" @dark={true} field={@field_form[:file_extensions]} />
                </div>
                <p class="mt-3 text-sm leading-6 text-gray-400">
                  Comma-seperated values. Example: .csv,.pdf,.html - Leave blank for all file types
                </p>
              </div>

              <fieldset>
                <legend class="text-base font-semibold leading-6 text-white">
                  Applicability
                </legend>

                <div class="mt-4 grid grid-cols-1 gap-y-6 sm:grid-cols-3 sm:gap-x-4">
                  <!-- Active: "border-indigo-600 ring-2 ring-indigo-600", Not Active: "border-gray-300" -->
                  <label class="relative flex cursor-pointer rounded-lg border  bg-gray-800 p-4 shadow-sm focus:outline-none">
                    <input
                      type="radio"
                      name="project-type"
                      value="Newsletter"
                      class="sr-only"
                      aria-labelledby="project-type-0-label"
                      aria-describedby="project-type-0-description-0 project-type-0-description-1"
                    />
                    <span class="flex flex-1">
                      <span class="flex flex-col">
                        <span id="project-type-0-label" class="block text-sm font-medium text-white">
                          Field-per-batch
                        </span>
                        <span
                          id="project-type-0-description-0"
                          class="mt-1 flex items-center text-sm text-white"
                        >
                          Show field only once per group of uploads.
                        </span>
                      </span>
                    </span>
                    <!-- Not Checked: "invisible" -->
                    <svg
                      class="h-5 w-5 text-white"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                        clip-rule="evenodd"
                      />
                    </svg>

                    <span
                      class="pointer-events-none absolute -inset-px rounded-lg border-2"
                      aria-hidden="true"
                    >
                    </span>
                  </label>
                  <label class="relative flex cursor-pointer rounded-lg border bg-white p-4 shadow-sm focus:outline-none">
                    <input
                      type="radio"
                      name="project-type"
                      value="Existing Customers"
                      class="sr-only"
                      aria-labelledby="project-type-1-label"
                      aria-describedby="project-type-1-description-0 project-type-1-description-1"
                    />
                    <span class="flex flex-1">
                      <span class="flex flex-col">
                        <span
                          id="project-type-1-label"
                          class="block text-sm font-medium text-gray-900"
                        >
                          Field-per-file
                        </span>
                        <span
                          id="project-type-1-description-0"
                          class="mt-1 flex items-center text-sm text-gray-500"
                        >
                          Show field once for each file that matches the desired extensions.
                        </span>
                      </span>
                    </span>
                    <!-- Not Checked: "invisible" -->
                    <svg
                      class="h-5 w-5 text-indigo-600"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                        clip-rule="evenodd"
                      />
                    </svg>

                    <span
                      class="pointer-events-none absolute -inset-px rounded-lg border-2"
                      aria-hidden="true"
                    >
                    </span>
                  </label>
                </div>
              </fieldset>
            </div>

            <div class="border-b border-white/10 pb-12">
              <h2 class="text-base font-semibold leading-7 text-white">Preview</h2>
              <p class="mt-1 text-sm leading-6 text-gray-400">
                This is how the field will appear on the final form
              </p>
              <div class="sm:col-span-4">
                <label for="username" class="block text-sm font-medium leading-6 text-white">
                  Label
                </label>
                <div class="mt-2">
                  <div class="flex rounded-md bg-white/5 ring-1 ring-inset ring-white/10 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500">
                    <input
                      type="text"
                      name="username"
                      id="username"
                      autocomplete="username"
                      class="flex-1 border-0 bg-transparent py-1.5 pl-1 text-white focus:ring-0 sm:text-sm sm:leading-6"
                      placeholder="janesmith"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-6 flex items-center justify-end gap-x-6">
            <button type="button" class="text-sm font-semibold leading-6 text-white">Cancel</button>
            <button
              type="submit"
              class="rounded-md bg-indigo-500 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
            >
              Save
            </button>
          </div>
        </form>
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
    field = Enum.find(socket.assigns.template.fields, fn field -> field.id == field_id end)

    {:noreply,
     socket
     |> assign(
       :field,
       field
     )
     |> assign(:field_form, to_form(Requests.change_template_field(field)))}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket |> assign(:field, nil)}
  end

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

  defp active(current, field) do
    if field && current == field.id do
      "flex items-center justify-between gap-x-6 py-5 active active:bg-green-100 bg-green-100 px-1 cursor-pointer drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
    else
      "flex items-center justify-between gap-x-6 py-5 px-1 cursor-pointer drag-item:focus-within:ring-0 drag-item:focus-within:ring-offset-0 drag-ghost:bg-zinc-300 drag-ghost:border-0 drag-ghost:ring-0"
    end
  end
end
