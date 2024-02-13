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
      <%= @text %>
    </div>
    """
  end

  @impl true
  def mount(params, session, socket) do
    form = to_form(%{"name" => "test"})

    {:ok,
     socket
     |> assign(:section, "metadata")
     |> assign(:text, HTML.Form.text_input(form, :name, class: "test")),
     layout: {IngestWeb.Layouts, :dashboard}}
  end
end
