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
    {:ok, socket |> assign(:section, "templates") |> assign(:templates, []),
     layout: {IngestWeb.Layouts, :dashboard}}
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
end
