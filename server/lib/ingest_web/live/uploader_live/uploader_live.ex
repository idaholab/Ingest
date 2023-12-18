defmodule IngestWeb.UploaderLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""

    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {IngestWeb.Layouts, :uploader}}
  end
end
