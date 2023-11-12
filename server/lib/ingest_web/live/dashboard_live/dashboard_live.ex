defmodule IngestWeb.DashboardLive do
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-base font-semibold leading-6 text-gray-900">Last 30 days</h3>
      <dl class="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-3">
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Total Subscribers</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">71,897</dd>
        </div>
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Avg. Open Rate</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">58.16%</dd>
        </div>
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Avg. Click Rate</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">24.57%</dd>
        </div>
      </dl>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:section, "dashboard"), layout: {IngestWeb.Layouts, :dashboard}}
  end
end
