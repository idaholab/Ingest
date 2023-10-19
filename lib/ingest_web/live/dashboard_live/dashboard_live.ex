defmodule IngestWeb.DashboardLive do
  use IngestWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "dashboard"), layout: {IngestWeb.Layouts, :dashboard}}
  end
end
