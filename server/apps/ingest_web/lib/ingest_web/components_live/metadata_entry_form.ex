defmodule IngestWeb.LiveComponents.MetadataEntryForm do
  @moduledoc """
  This form takes a template and data from its parent LiveView and dynamically renders a
  form based on the template and already provided data.
  """
  alias Ingest.Uploads
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="space-y-10 divide-y divide-gray-900/10">
        <div class="grid grid-cols-1 gap-x-8 gap-y-8 md:grid-cols-3">
          <div :if={@metadata.submitted} class="px-4 sm:px-0">
            <h2 class="text-base font-semibold leading-7 text-gray-500"><%= @title %></h2>
            <p class="mt-1 text-sm leading-6 text-gray-400">
              <%= @description %>
            </p>
          </div>

          <div :if={!@metadata.submitted} class="px-4 sm:px-0">
            <h2 class="text-base font-semibold leading-7 text-gray-900"><%= @title %></h2>
            <p class="mt-1 text-sm leading-6 text-gray-600">
              <%= @description %>
            </p>
          </div>

          <div :if={@metadata.submitted} class="rounded-md bg-green-50 p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-5 w-5 text-green-400"
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
              </div>
              <div class="ml-3">
                <p class="text-sm font-medium text-green-800">Section Submitted!</p>
              </div>
            </div>
          </div>

          <.simple_form
            :if={!@metadata.submitted}
            id="metadata_form"
            for={@metadata_form}
            phx-change="validate"
            phx-target={@myself}
            phx-submit="save"
          >
            <div :for={field <- @fields} class="py-2">
              <.input
                label={field.label}
                name={field.label}
                required={field.required}
                field={@metadata_form[field.label]}
                prompt="Select one"
                type={Atom.to_string(field.type)}
                options={
                  if field.type == :select do
                    field.select_options
                  else
                    if field.type == :branch do
                      branch_options_display(field.branch_options)
                    else
                      nil
                    end
                  end
                }
              />
              <div :if={@errors != nil}>
                <.error :for={{key, msg} <- @errors} :if={key == field.label}>
                  <%= msg %>
                </.error>
              </div>
              <p :if={field.help_text} class="text-xs">
                <%= raw(Earmark.as_html!(field.help_text)) %>
              </p>
              <p :if={field.required} class="text-xs text-red-400">*Required</p>

              <div :if={field.type == :branch} class="mt-2">
                <div
                  :for={branch_field <- get_branch_fields(field, @metadata_form[field.label].value)}
                  class="py-2"
                >
                  <.input
                    label={branch_field.label}
                    name={branch_field.label}
                    required={branch_field.required}
                    field={@metadata_form[branch_field.label]}
                    type={Atom.to_string(branch_field.type)}
                    prompt="Select one"
                    options={
                      if branch_field.type == :select do
                        branch_field.select_options
                      else
                        if branch_field.type == :branch do
                          branch_options_display(field.branch_options)
                        else
                          nil
                        end
                      end
                    }
                  />
                  <div :if={@errors != nil}>
                    <.error :for={{key, msg} <- @errors} :if={key == branch_field.label}>
                      <%= msg %>
                    </.error>
                  </div>
                  <p :if={branch_field.help_text} class="text-xs">
                    <%= raw(Earmark.as_html!(branch_field.help_text)) %>
                  </p>
                  <p :if={branch_field.required} class="text-xs text-red-400">*Required</p>
                </div>
              </div>
            </div>

            <div class="mt-6 flex items-center justify-end gap-x-6">
              <button
                :if={@errors == nil && @metadata.data && map_size(@metadata.data) > 0}
                class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                phx-disable-with="Saving..."
                name="save"
                value="submit"
                data-confirm="Are you sure? You cannot edit your input after submission"
              >
                Submit Section
              </button>
              <button
                :if={@errors != nil || (is_nil(@metadata.data) || map_size(@metadata.data) == 0)}
                class="rounded-md bg-gray-300 px-3 py-2 text-sm font-semibold text-white shadow-sm  focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                phx-disable-with="Saving..."
                name="save"
                value="submit"
                disabled
              >
                Submit Section
              </button>
              <.button
                :if={@errors == nil}
                class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                phx-disable-with="Saving..."
                name="save"
                value="save"
              >
                Save Section
              </.button>
              <button
                :if={@errors != nil}
                class="rounded-md bg-gray-300 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-gray-300 disabled:opacity-75"
                phx-disable-with="Saving..."
                name="save"
                value="save"
                disabled
              >
                Save Section
              </button>
            </div>
          </.simple_form>
        </div>
      </div>
      <div class="relative">
        <div class="absolute inset-0 flex items-center" aria-hidden="true">
          <div class="w-full border-t border-gray-300"></div>
        </div>
        <div class="relative flex justify-center">
          <span class="bg-white px-2 text-gray-500">
            <svg
              class="h-5 w-5 text-gray-500"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
            </svg>
          </span>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{template: template, upload: upload} = _assigns, socket) do
    metadata = Ingest.Uploads.list_metadata_by(upload, template)

    # if there's no metadata, means we need to quickly write a record for it
    metadata =
      if metadata do
        metadata
      else
        {:ok, m} =
          Uploads.create_metadata(%{
            submitted: false,
            data: %{},
            upload_id: upload.id,
            template_id: template.id
          })

        m
      end

    {:ok,
     socket
     |> assign(:title, template.name)
     |> assign(:description, template.description)
     |> assign(:metadata, metadata)
     |> assign(:upload, upload)
     |> assign(
       :metadata_form,
       to_form(metadata.data)
     )
     |> assign(:errors, nil)
     |> assign(:template, template)
     |> assign(:fields, template.fields)}
  end

  @impl true
  def handle_event("validate", %{"_target" => target} = params, socket) do
    field = Enum.find(socket.assigns.fields, fn f -> f.label == List.first(target) end)

    # basically all we need to verify currently is whether or not the field is required
    # and if it is, throw an error if it's empty
    if params[List.first(target)] == "" && field && field.required do
      {:noreply,
       socket
       |> assign(:metadata_form, to_form(params))
       |> assign(:errors, %{List.first(target) => "Field is Required"})}
    else
      {:noreply, socket |> assign(:errors, nil) |> assign(:metadata_form, to_form(params))}
    end
  end

  @impl true
  def handle_event("save", %{"save" => save_type} = params, socket) do
    case Uploads.update_metadata(socket.assigns.metadata, %{
           data: params,
           submitted: save_type == "submit"
         }) do
      {:ok, metadata} ->
        # force update until we finish the feature
        %{upload_id: socket.assigns.upload.id}
        |> Ingest.Workers.Metadata.new()
        |> Oban.insert()

        notify_parent({:saved, metadata})

        {:noreply,
         socket
         |> assign(:metadata, metadata)
         |> assign(:metadata_form, to_form(metadata.data))}

      {:error, %Ecto.Changeset{} = changeset} ->
        notify_parent({:error, changeset})
        {:noreply, socket}
    end

    {:noreply, socket}
  end

  defp get_branch_fields(field, branch) do
    if !field do
      []
    else
      option =
        field.branch_options
        |> Enum.find(fn option -> option["name"] == branch end)

      if option do
        Ingest.Requests.get_template!(option["template"]).fields
      else
        []
      end
    end
  end

  defp branch_options_display(options) do
    options
    |> Enum.map(fn %{"name" => name, "template" => _template} -> name end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
