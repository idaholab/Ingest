defmodule IngestWeb.TemplatesLive do
  alias Ingest.Requests.Template
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={!@templates || Enum.empty?(@templates)} class="text-center">
        <.icon name="hero-folder-plus" class="mx-auto h-12 w-12 text-gray-400" />
        <h3 class="mt-2 text-sm font-semibold text-gray-900">No templates</h3>
        <p class="mt-1 text-sm text-gray-500">Get started by creating a new template.</p>
        <.link
          patch={~p"/dashboard/templates/new"}
          type="button"
          class="mt-5 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          <.icon name="hero-plus" /> New Template
        </.link>
      </div>

      <div :if={@templates && !Enum.empty?(@templates)} class="px-4 sm:px-6 lg:px-8">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-gray-900">Metadata Templates</h1>
            <p class="mt-2 text-sm text-gray-700">
              A list of all the templates you own or are a part of. Metadata Templates are forms that enforce metadata collection at time of file upload.
            </p>
          </div>
          <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
            <div class="mt-6">
              <.link patch={~p"/dashboard/templates/new"}>
                <button
                  type="button"
                  class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  <.icon name="hero-plus" /> New Template
                </button>
              </.link>
            </div>
          </div>
        </div>
        <div class="mt-8 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <.table
                id="templates"
                rows={@streams.templates}
                row_click={
                  fn {_id, template} -> JS.navigate(~p"/dashboard/templates/#{template}") end
                }
              >
                <:col :let={{_id, template}} label="Name"><%= template.name %></:col>
                <:col :let={{_id, template}} label="Description">
                  <%= template.description %>
                </:col>

                <:action :let={{_id, template}}>
                  <.link
                    navigate={~p"/dashboard/templates/#{template}"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Show
                  </.link>
                </:action>
                <:action :let={{id, template}}>
                  <.link
                    :if={
                      Bodyguard.permit?(
                        Ingest.Requests.Template,
                        :delete_template,
                        @current_user,
                        template
                      )
                    }
                    class="text-red-600 hover:text-red-900"
                    phx-click={JS.push("delete", value: %{id: template.id}) |> hide("##{id}")}
                    data-confirm="Are you sure?"
                  >
                    Delete
                  </.link>
                </:action>
              </.table>
            </div>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action in [:new]}
        id="template_modal"
        show
        on_cancel={JS.patch(~p"/dashboard/templates")}
      >
        <.live_component
          live_action={@live_action}
          template_form={@template_form}
          template={@template}
          module={IngestWeb.LiveComponents.TemplateForm}
          id="template-modal-component"
          current_user={@current_user}
        />
      </.modal>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:section, "templates")
     |> assign(:templates, Ingest.Requests.list_owned_templates(socket.assigns.current_user))
     |> stream(
       :templates,
       Ingest.Requests.list_owned_templates(socket.assigns.current_user)
     ), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Template")
    |> assign(:template_form, %Template{} |> Ecto.Changeset.change() |> to_form())
    |> assign(:template, %Template{inserted_by: socket.assigns.current_user.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing templates")
    |> assign(:template, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    with :ok <-
           Bodyguard.permit(
             Ingest.Requests.template(),
             :delete_template,
             socket.assigns.current_user,
             socket.assigns.request
           ),
         template <- Ingest.Requests.get_template!(id),
         {:ok, _} <- Ingest.Requests.delete_template(template) do
      {:noreply, stream_delete(socket, :templates, template)}
    else
      _ -> {:noreply, socket |> put_flash(:error, "Not Authorized")}
    end
  end
end
