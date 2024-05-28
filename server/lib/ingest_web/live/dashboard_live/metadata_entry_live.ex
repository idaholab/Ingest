defmodule IngestWeb.MetadataEntryLive do
  @moduledoc """
  MetadataEntryLive is the component which allows users to enter metadata for their uploads. This corresponds to the Uploads.Metadata
  data structure. Experience should be someone navigates to this page for an upload, and are met with a dynamic form on the right hand
  side already filled in with answers they may have given previously.
  """
  alias Ingest.Uploads
  alias Ingest.Requests
  use IngestWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <nav aria-label="Progress" class="sticky top-20 mb-10 w-1/6">
        <p class="text-lg">Progress</p>
        <ol role="list" class="flex items-center">
          <a href="#">
            <.icon name="hero-home" class="h-5 w-5 " />
          </a>
          <li class="relative pr-8 sm:pr-20 [&:not(:last-child)]:pr-8 [&:not(:last-child)]:sm:pr-20">
            <!-- Completed Step -->
            <div class="absolute inset-0 flex items-center" aria-hidden="true">
              <div class="h-0.5 w-full bg-indigo-600"></div>
            </div>
          </li>
          <%= for template <- @templates do %>
            <li
              :if={Enum.find(@upload.metadatas, fn u -> u.template_id == template.id end)}
              class="relative  [&:not(:last-child)]:pr-8 [&:not(:last-child)]:sm:pr-20"
            >
              <!-- Completed Step -->
              <div class="absolute inset-0 flex items-center" aria-hidden="true">
                <div class="h-0.5 w-full bg-indigo-600"></div>
              </div>
              <a
                href={"##{template.name}"}
                class="relative flex h-8 w-8 items-center justify-center rounded-full bg-indigo-600 hover:bg-indigo-900"
              >
                <svg
                  class="h-5 w-5 text-white"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fill-rule="evenodd"
                    d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                    clip-rule="evenodd"
                  />
                </svg>
                <span class="sr-only">Step 1</span>
              </a>
            </li>
            <li
              :if={!Enum.find(@upload.metadatas, fn u -> u.template_id == template.id end)}
              class="relative [&:not(:last-child)]:pr-8 [&:not(:last-child)]:sm:pr-20"
            >
              <!-- Upcoming Step -->
              <div class="absolute inset-0 flex items-center" aria-hidden="true">
                <div class="h-0.5 w-full bg-gray-200"></div>
              </div>
              <a
                href={"##{template.name}"}
                class="group relative flex h-8 w-8 items-center justify-center rounded-full border-2 border-gray-300 bg-white hover:border-gray-400"
              >
                <span
                  class="h-2.5 w-2.5 rounded-full bg-transparent group-hover:bg-gray-300"
                  aria-hidden="true"
                >
                </span>
                <span class="sr-only">Step 4</span>
              </a>
            </li>
          <% end %>
        </ol>
      </nav>

      <%= for template <- @templates do %>
        <div id={template.name} class="target:pt-40"></div>
        <.live_component
          module={IngestWeb.LiveComponents.MetadataEntryForm}
          upload={@upload}
          template={template}
          id={"template-#{template.id}"}
        />
      <% end %>

      <div
        :if={
          length(Enum.filter(@upload.metadatas, fn u -> u.submitted end)) != length(@templates) ||
            @upload.metadatas == []
        }
        class="flex bg-white shadow sm:rounded-lg justify-center"
      >
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-base font-semibold leading-6 text-gray-900">Complete Entry Task</h3>
          <div class="mt-2 max-w-xl text-sm text-gray-500">
            <p>
              Once you have completed and submitted all sections, this task will automatically complete.
            </p>
          </div>
        </div>
      </div>

      <div
        :if={
          length(Enum.filter(@upload.metadatas, fn u -> u.submitted end)) == length(@templates) &&
            @upload.metadatas != []
        }
        class="rounded-md bg-green-50 p-4"
      >
        <div class="flex">
          <div class="flex-shrink-0">
            <svg
              class="h-5 w-5 text-green-400"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-green-800">Task completed</h3>
            <div class="mt-2 text-sm text-green-700">
              <p>
                Metadata successfully submitted. You can navigate away from this page.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(%{email: nil}))
     |> assign(:section, "metadata")
     |> assign(:test, nil), layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(%{"upload_id" => upload_id, "id" => req_id}, _uri, socket) do
    request = Requests.get_request!(req_id)
    upload = Uploads.get_upload!(upload_id)

    {:noreply,
     socket
     |> assign(:templates, request.templates)
     |> assign(:upload, upload)
     |> assign(:request, request)}
  end

  @impl true
  def handle_info({IngestWeb.LiveComponents.MetadataEntryForm, {:saved, _metadata}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Section saved successfully")
     |> push_navigate(
       to: ~p"/dashboard/uploads/#{socket.assigns.request}/#{socket.assigns.upload}"
     )}
  end

  @impl true
  def handle_info({IngestWeb.LiveComponents.MetadataEntryForm, {:error, _changeset}}, socket) do
    {:noreply, socket |> put_flash(:error, "Unable to save section")}
  end
end
