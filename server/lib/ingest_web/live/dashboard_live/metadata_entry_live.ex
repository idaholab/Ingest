defmodule IngestWeb.MetadataEntryLive do
  @moduledoc """
  MetadataEntryLive is the component which allows users to enter metadata for their uploads. This corresponds to the Uploads.Metadata
  data structure. Experience should be someone navigates to this page for an upload, and are met with a dynamic form on the right hand
  side already filled in with answers they may have given previously.
  """
  use IngestWeb, :live_view
  alias Phoenix.HTML

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} phx-submit="save">
        <.input field={@form[:email]} label="Email" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"name" => "test"})

    {:ok,
     socket
     |> assign(:form, to_form(%{email: nil}))
     |> assign(:section, "metadata")
     |> assign(:text, HTML.Form.text_input(form, :name, class: "test")),
     layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("save", %{"email" => email}, socket) do
    dbg(email)
    {:noreply, socket}
  end
end
