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
          <div class="px-4 sm:px-0">
            <h2 class="text-base font-semibold leading-7 text-gray-900"><%= @title %></h2>
            <p class="mt-1 text-sm leading-6 text-gray-600">
              <%= @description %>
            </p>
          </div>

          <.simple_form
            id="metadata_form"
            for={@metadata_form}
            phx-change="validate"
            phx-target={@myself}
            phx-submit="save"
            class=""
          >
            <div :for={field <- @fields}>
              <.input
                label={field.label}
                name={field.label}
                field={@metadata_form[field.label]}
                type={Atom.to_string(field.type)}
                options={
                  if field.type == :select do
                    field.select_options
                  else
                    nil
                  end
                }
              />
              <div :if={@errors != nil}>
                <.error :for={{key, msg} <- @errors} :if={key == field.label}>
                  <%= msg %>
                </.error>
              </div>
              <p class="text-xs"><%= field.help_text %></p>
            </div>

            <div class="mt-6 flex items-center justify-end gap-x-6">
              <.button
                :if={@errors == nil}
                class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                phx-disable-with="Saving..."
              >
                Save Section
              </.button>
              <button
                :if={@errors != nil}
                class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 disabled:bg-gray-900 disabled:opacity-75"
                phx-disable-with="Saving..."
                disabled
              >
                Save Section
              </button>
            </div>
          </.simple_form>
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
     |> assign(
       :metadata_form,
       to_form(metadata.data)
     )
     |> assign(:errors, nil)
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
       |> assign(:errors, %{List.first(target) => "Test"})}
    else
      {:noreply, socket |> assign(:errors, nil)}
    end
  end

  @impl true
  def handle_event("save", params, socket) do
    case Uploads.update_metadata(socket.assigns.metadata, %{data: params}) do
      {:ok, metadata} ->
        notify_parent({:saved, metadata})

        {:noreply,
         socket
         |> assign(:metadata_form, to_form(metadata.data))}

      {:error, %Ecto.Changeset{} = changeset} ->
        notify_parent({:error, changeset})
        {:noreply, socket}
    end

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
