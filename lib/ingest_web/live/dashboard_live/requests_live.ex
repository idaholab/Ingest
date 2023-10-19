defmodule IngestWeb.RequestsLive do
  use IngestWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "requests"), layout: {IngestWeb.Layouts, :dashboard}}
  end
end
