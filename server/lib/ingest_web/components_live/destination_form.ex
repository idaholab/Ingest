defmodule IngestWeb.LiveComponents.DestinationForm do
  @moduledoc """
  Destination Form is the form for creating/editing Destinations
  """
  use IngestWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@destination_form}
        phx-change="validate"
        phx-target={@myself}
        id="destination"
        phx-submit="save"
      >
        <div class="space-y-12">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3">
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">New Destination</h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Create a new Destination. A Destination is where your data will be placed, along with its metadata, after a user uploads it via Ingest.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.label for="status-select">
                  Destination Name
                </.label>
                <.input type="text" field={@destination_form[:name]} />
              </div>

              <div class="sm:col-span-4">
                <.label for="project-type">
                  Destination Type
                </.label>
                <.input
                  type="select"
                  field={@destination_form[:type]}
                  options={[
                    {"AWS S3", :s3},
                    {"Azure Blob Storage", :azure},
                    {"LakeFS Repository", :lakefs}
                  ]}
                />
              </div>

              <div :if={Application.get_env(:ingest, :show_classifications)} class="sm:col-span-6">
                <.label for="project-type">Data Classifications Allowed</.label>
                <.input
                  type="checkbox"
                  field={@destination_form[:ouo]}
                  label="OUO - Official Use Only"
                />

                <.input
                  type="checkbox"
                  field={@destination_form[:pii]}
                  label="PII - Personally Identifiable Information"
                />

                <.input type="checkbox" field={@destination_form[:ec]} label="EC - Export Controlled" />

                <.input
                  type="checkbox"
                  field={@destination_form[:ucni]}
                  label="UCNI - Unclassified Controlled Nuclear Information"
                />

                <.input
                  type="checkbox"
                  field={@destination_form[:cui]}
                  label="CUI - Controlled Unclassifed Information"
                />

                <.input
                  type="checkbox"
                  field={@destination_form[:uur]}
                  label="UUR - Unclassified Unlimited Release"
                />
              </div>
            </div>
          </div>

          <div
            :if={@type == "temporary"}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                Temporary Data Destination
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                This is a temporary storage for your data. We will hold on to it for a set number of days, allowing you to download it via our API. Once the day limit has been reached, your data will be deleted.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-4">
                <.inputs_for :let={config} field={@destination_form[:temporary_config]}>
                  <.label for="status-select">
                    Data Retention Limit (Days)
                  </.label>
                  <.input type="number" max="30" field={config[:limit]} />
                </.inputs_for>
              </div>
            </div>
          </div>

          <div
            :if={@type == "s3" and assigns.live_action == :new}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                AWS S3 Credentials
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Your AWS S3 credentials for the data's location after it's been uploaded by the user.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-6">
                <.inputs_for :let={config} field={@destination_form[:s3_config]}>
                  <.label for="status-select">
                    Access Key ID
                  </.label>
                  <.input type="text" field={config[:access_key_id]} />

                  <.label for="status-select">
                    Secret Access Key
                  </.label>
                  <.input type="text" field={config[:secret_access_key]} />

                  <.label for="status-select">
                    URL
                  </.label>
                  <.input type="text" field={config[:base_url]} />

                  <.label for="status-select">
                    Bucket
                  </.label>
                  <.input type="text" field={config[:bucket]} />

                  <.label for="status-select">
                    Region
                  </.label>
                  <.input type="text" field={config[:region]} />

                  <.label for="status-select">
                    Root Path
                  </.label>
                  <.input type="text" field={config[:path]} />
                </.inputs_for>
              </div>
            </div>
          </div>
          <div
            :if={@type == "s3" and assigns.live_action == :edit}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                AWS S3 Credentials
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Your AWS S3 credentials for the data's location after it's been uploaded by the user.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-6">
                <.inputs_for :let={config} field={@destination_form[:s3_config]}>
                  <.label for="status-select">
                    Access Key ID
                  </.label>
                  <input
                    disabled
                    type="password"
                    value="************"
                    class="rounded border-zinc-300 text-zinc-900 focus:ring-0  disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none"
                  />

                  <.label for="status-select">
                    Secret Access Key
                  </.label>
                  <input
                    disabled
                    type="password"
                    value="************"
                    class="rounded border-zinc-300 text-zinc-900 focus:ring-0  disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none"
                  />

                  <.label for="status-select">
                    URL
                  </.label>
                  <.input type="text" field={config[:base_url]} />

                  <.label for="status-select">
                    Bucket
                  </.label>
                  <.input type="text" field={config[:bucket]} />

                  <.label for="status-select">
                    Region
                  </.label>
                  <.input type="text" field={config[:region]} />

                  <.label for="status-select">
                    Root Path
                  </.label>
                  <.input type="text" field={config[:path]} />
                </.inputs_for>
              </div>
            </div>
          </div>

          <div
            :if={@type == "lakefs" and assigns.live_action == :new}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                LakeFS Credentials
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Your LakeFS credentials - make sure that you have sufficient permissions to work with the repository you choose.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-6">
                <.inputs_for :let={config} field={@destination_form[:lakefs_config]}>
                  <.label for="status-select">
                    Access Key ID
                  </.label>
                  <.input type="text" field={config[:access_key_id]} />

                  <.label for="status-select">
                    Secret Access Key
                  </.label>
                  <.input type="text" field={config[:secret_access_key]} />

                  <.label for="status-select">
                    URL
                  </.label>
                  <.input type="text" field={config[:base_url]} />
                  <p class="text-xs">
                    Leave the trailing / off the url.
                  </p>

                  <.label for="status-select">
                    Port
                  </.label>
                  <.input type="text" field={config[:port]} />
                  <p class="text-xs">
                    When in doubt, leave blank.
                  </p>

                  <.label for="status-select">
                    SSL
                  </.label>
                  <.input type="checkbox" field={config[:ssl]} />
                  <p class="text-xs">
                    When in doubt, enable this setting.
                  </p>

                  <.button
                    class="rounded-md bg-indigo-600 px-3 py-2 mt-3 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    phx-disable-with="Saving..."
                    name="save"
                    value="test_connection"
                  >
                    Test Connection
                  </.button>

                  <.label for="status-select">
                    Repositories
                  </.label>
                  <.input
                    :if={@lakefs_repos != [] || config[:repository]}
                    type="select"
                    options={
                      if @destination.lakefs_config do
                        [
                          @destination.lakefs_config.repository
                          | @lakefs_repos |> Enum.map(fn r -> r["id"] end)
                        ]
                      else
                        @lakefs_repos |> Enum.map(fn r -> r["id"] end)
                      end
                    }
                    field={config[:repository]}
                  />
                </.inputs_for>
                <p :if={@lakefs_repos == []} class="text-xs">
                  Test connection to load repositories for selection
                </p>
              </div>
            </div>
          </div>

          <div
            :if={@type == "lakefs" and assigns.live_action == :edit}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                LakeFS Credentials
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Your LakeFS credentials - make sure that you have sufficient permissions to work with the repository you choose.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-6">
                <.inputs_for :let={config} field={@destination_form[:lakefs_config]}>
                  <.label for="status-select">
                    Access Key ID
                  </.label>
                  <input
                    disabled
                    type="password"
                    value="************"
                    class="rounded border-zinc-300 text-zinc-900 focus:ring-0  disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none"
                  />

                  <.label for="status-select">
                    Secret Access Key
                  </.label>
                  <input
                    disabled
                    type="password"
                    value="************"
                    class="rounded border-zinc-300 text-zinc-900 focus:ring-0  disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none"
                  />

                  <.label for="status-select">
                    URL
                  </.label>
                  <.input type="text" field={config[:base_url]} />
                  <p class="text-xs">
                    Leave the trailing / off the url.
                  </p>

                  <.label for="status-select">
                    Port
                  </.label>
                  <.input type="text" field={config[:port]} />
                  <p class="text-xs">
                    When in doubt, leave blank.
                  </p>

                  <.label for="status-select">
                    SSL
                  </.label>
                  <.input type="checkbox" field={config[:ssl]} />
                  <p class="text-xs">
                    When in doubt, enable this setting.
                  </p>

                  <.button
                    class="rounded-md bg-indigo-600 px-3 py-2 mt-3 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    phx-disable-with="Saving..."
                    name="save"
                    value="test_connection"
                  >
                    Test Connection
                  </.button>

                  <.label for="status-select">
                    Repositories
                  </.label>
                  <.input
                    :if={@lakefs_repos != [] || config[:repository]}
                    type="select"
                    options={
                      if @destination.lakefs_config do
                        [
                          @destination.lakefs_config.repository
                          | @lakefs_repos |> Enum.map(fn r -> r["id"] end)
                        ]
                      else
                        @lakefs_repos |> Enum.map(fn r -> r["id"] end)
                      end
                    }
                    field={config[:repository]}
                  />
                </.inputs_for>
                <p :if={@lakefs_repos == []} class="text-xs">
                  Test connection to load repositories for selection
                </p>
              </div>
            </div>
          </div>

          <div
            :if={@type == "azure" and assigns.live_action == :new}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                Azure Data Lake Credentials
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Your Azure credentials for the data's location after it's been uploaded by the user, and before you review and potentially modify it.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-6">
                <.inputs_for :let={config} field={@destination_form[:azure_config]}>
                  <.label for="status-select">
                    Account Name
                  </.label>
                  <.input type="text" field={config[:account_name]} />
                  <p class="text-xs">
                    This field is stored in an encrypted state and will not be made available to other users of the destination
                  </p>

                  <.label for="status-select">
                    Account Key
                  </.label>
                  <.input type="text" field={config[:account_key]} />
                  <p class="text-xs">
                    This field is stored in an encrypted state and will not be made available to other users of the destination
                  </p>

                  <.label for="status-select">
                    Base Service URL
                  </.label>
                  <.input type="text" field={config[:base_url]} />
                  <p class="text-xs">
                    Leave blank to use the service's default option.
                  </p>

                  <.label for="status-select">
                    SSL
                  </.label>
                  <.input type="checkbox" field={config[:ssl]} />
                  <p class="text-xs">
                    When in doubt, enable this setting.
                  </p>

                  <.label for="status-select">
                    Container
                  </.label>
                  <.input type="text" field={config[:container]} />
                </.inputs_for>
              </div>
            </div>
          </div>

          <div
            :if={@type == "azure" and assigns.live_action == :edit}
            class="grid grid-cols-1 gap-x-8 gap-y-10 border-b border-gray-900/10 pb-12 md:grid-cols-3"
          >
            <div>
              <h2 class="text-base font-semibold leading-7 text-gray-900">
                Azure Data Lake Credentials
              </h2>
              <p class="mt-1 text-sm leading-6 text-gray-600">
                Your Azure credentials for the data's location after it's been uploaded by the user, and before you review and potentially modify it.
              </p>
            </div>

            <div class="grid max-w-2xl grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6 md:col-span-2">
              <div class="sm:col-span-6">
                <.inputs_for :let={config} field={@destination_form[:azure_config]}>
                  <.label for="status-select">
                    Account Name
                  </.label>
                  <input
                    disabled
                    type="password"
                    value="************"
                    class="rounded border-zinc-300 text-zinc-900 focus:ring-0  disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none"
                  />
                  <p class="text-xs">
                    This field is stored in an encrypted state and will not be made available to other users of the destination
                  </p>

                  <.label for="status-select">
                    Account Key
                  </.label>
                  <input
                    disabled
                    type="password"
                    value="************"
                    class="rounded border-zinc-300 text-zinc-900 focus:ring-0  disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none"
                  />
                  <p class="text-xs">
                    This field is stored in an encrypted state and will not be made available to other users of the destination
                  </p>

                  <.label for="status-select">
                    Base Service URL
                  </.label>
                  <.input type="text" field={config[:base_url]} />
                  <p class="text-xs">
                    Leave blank to use the service's default option.
                  </p>

                  <.label for="status-select">
                    SSL
                  </.label>
                  <.input type="checkbox" field={config[:ssl]} />
                  <p class="text-xs">
                    When in doubt, enable this setting.
                  </p>

                  <.label for="status-select">
                    Container
                  </.label>
                  <.input type="text" field={config[:container]} />
                </.inputs_for>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.button
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            phx-disable-with="Saving..."
            name="save"
            value="save"
          >
            Save
          </.button>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{destination: destination} = assigns, socket) do
    changeset = Ingest.Destinations.display_destination(destination)

    {:ok,
     socket
     |> assign(:type, Atom.to_string(destination.type))
     |> assign(assigns)
     |> assign(:lakefs_repos, [])
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"destination" => destination_params}, socket) do
    changeset =
      socket.assigns.destination
      |> Ingest.Destinations.change_destination(destination_params)
      |> Map.put(:action, :validate)

    {:noreply,
     assign_form(socket |> assign(:type, Map.get(destination_params, "type")), changeset)}
  end

  def handle_event(
        "save",
        %{"save" => save_type, "destination" => destination_params} = _params,
        socket
      ) do
    case save_type do
      "save" ->
        save_destination(socket, socket.assigns.live_action, destination_params)

      # currently this only applies to the LakeFS destination, and will populate the repositories and remove the disabled tag
      "test_connection" ->
        base_url =
          if destination_params["lakefs_config"]["ssl"] == true do
            "https://#{destination_params["lakefs_config"]["base_url"]}"
          else
            "http://#{destination_params["lakefs_config"]["base_url"]}"
          end

        client =
          Ingest.Destinations.Lakefs.new_client(
            base_url,
            {
              destination_params["lakefs_config"]["access_key_id"],
              destination_params["lakefs_config"]["secret_access_key"]
            },
            port: destination_params["lakefs_config"]["port"]
          )

        {:ok, repos} = Ingest.Destinations.Lakefs.list_repos(client)

        {:noreply,
         socket
         |> assign(:lakefs_repos, repos)}
    end
  end

  defp save_destination(socket, :edit, destination_params) do
    destination_params =
      Map.put(
        destination_params,
        "classifications_allowed",
        collect_classifications(destination_params)
      )

    case Ingest.Destinations.update_destination(socket.assigns.destination, destination_params) do
      {:ok, destination} ->
        notify_parent({:saved, destination})

        {:noreply,
         socket
         |> put_flash(:info, "Destination updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_destination(socket, :new, destination_params) do
    destination_params =
      Map.put(
        destination_params,
        "classifications_allowed",
        collect_classifications(destination_params)
      )

    case Map.put(destination_params, "inserted_by", socket.assigns.current_user.id)
         |> Ingest.Destinations.create_destination() do
      {:ok, destination} ->
        notify_parent({:saved, destination})

        {:noreply,
         socket
         |> put_flash(:info, "Destination created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :destination_form, to_form(changeset))
  end

  defp collect_classifications(form) do
    elems =
      :maps.filter(fn _k, v -> v == "true" end, %{
        ouo: form["ouo"],
        pii: form["pii"],
        ucni: form["ucni"],
        cui: form["cui"],
        uur: form["uur"]
      })

    Map.keys(elems)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
