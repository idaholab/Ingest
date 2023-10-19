defmodule IngestWeb.TemplatesLive do
  use IngestWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "templates"), layout: {IngestWeb.Layouts, :dashboard}}
  end
end
