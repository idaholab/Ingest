defmodule IngestWeb.LiveComponents.DestinationForm do
  @moduledoc """
  Destination Form is the form for creating/editing Destinations
  """
  alias Ingest.Destinations.LakefsClient
  use IngestWeb, :live_component
  require Logger

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
                <div class="pb-1">
                  <.input
                    type="checkbox"
                    field={@destination_form[:ouo]}
                    label="OUO - Official Use Only"
                  />
                </div>

                <div class="pb-1">
                  <.input
                    type="checkbox"
                    field={@destination_form[:pii]}
                    label="PII - Personally Identifiable Information"
                  />
                </div>

                <div class="pb-1">
                  <.input
                    type="checkbox"
                    field={@destination_form[:ec]}
                    label="EC - Export Controlled"
                  />
                </div>

                <div class="pb-1">
                  <.input
                    type="checkbox"
                    field={@destination_form[:ucni]}
                    label="UCNI - Unclassified Controlled Nuclear Information"
                  />
                </div>

                <div class="pb-1">
                  <.input
                    type="checkbox"
                    field={@destination_form[:cui]}
                    label="CUI - Controlled Unclassifed Information"
                  />
                </div>

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
            :if={@type == "s3"}
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
                  <.input type="password" field={config[:access_key_id]} />

                  <.label for="status-select">
                    Secret Access Key
                  </.label>
                  <.input type="password" field={config[:secret_access_key]} />

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

                  <.label for="status-select">
                    Integrated Metadata
                  </.label>
                  <.input type="checkbox" field={config[:integrated_metadata]} />
                  <p class="text-xs">
                    Whether or not to use this destination's type native method for storing metadata.
                  </p>
                </.inputs_for>
              </div>
            </div>
          </div>

          <div
            :if={@type == "lakefs"}
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
                  <.input type="password" field={config[:access_key_id]} />

                  <.label for="status-select">
                    Secret Access Key
                  </.label>
                  <.input type="password" field={config[:secret_access_key]} />

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

                  <.label for="status-select">
                    Integrated Metadata
                  </.label>
                  <.input type="checkbox" field={config[:integrated_metadata]} />
                  <p class="text-xs">
                    Whether or not to use this destination's type native method for storing metadata.
                  </p>

                  <.label for="repo-per-project">
                    Repo per Project
                  </.label>
                  <.input
                    type="checkbox"
                    field={@destination_form[:repo_per_project]}
                    label="Repo per project"
                  />

                  <.button
                    class="rounded-md bg-indigo-600 px-3 py-2 mt-3 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    phx-submit="save"
                    phx-disable-with="Saving..."
                    name="action"
                    value="test_connection"
                  >
                    Test Connection
                  </.button>
                  <.label for="status-select">
                    Repositories
                  </.label>
                  <.input
                    :if={@lakefs_repos != [] or config[:repository]}
                    type="select"
                    options={
                      case @lakefs_repos do
                        %{"results" => results} when is_list(results) ->
                          results
                          |> Enum.map(fn %{"id" => id} -> id end)
                        [] ->
                          []
                        nil ->
                          []
                        other ->
                          Logger.error("Unexpected structure for @lakefs_repos: #{inspect(other)}")
                          []
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
            :if={@type == "azure"}
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
                  <.input type="password" field={config[:account_key]} />
                  <p class="text-xs">
                    This field is stored in an encrypted state and will not be made available to other users of the destination
                  </p>

                  <.label for="status-select">
                    Base Service URL
                  </.label>
                  <.input type="text" field={config[:base_url]} />
                  <p class="text-xs">
                    Leave blank to use the service's default option. Do not include trailing slashes or "https://".
                  </p>

                  <.label for="status-select">
                    SSL
                  </.label>
                  <.input type="checkbox" field={config[:ssl]} />
                  <p class="text-xs">
                    When in doubt, enable this setting.
                  </p>

                  <.label for="status-select">
                    Integrated Metadata
                  </.label>
                  <.input type="checkbox" field={config[:integrated_metadata]} />
                  <p class="text-xs">
                    Whether or not to use this destination's type native method for storing metadata.
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
          phx-submit="save"
          name="action"
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
  def update(assigns, socket) do
    destination = assigns[:destination] || %Ingest.Destinations.Destination{}
    changeset = Ingest.Destinations.change_destination(destination)

    lakefs_repos =
      if socket.assigns[:lakefs_repos] do
        socket.assigns.lakefs_repos
      else
        load_lakefs_repos(assigns)
      end

    {:ok,
      socket
      |> assign(:type, Atom.to_string(destination.type))
      |> assign(assigns)
      |> assign(:lakefs_repos, lakefs_repos)
      |> assign(:destination, destination)
      |> assign_form(changeset)}
  end

  defp load_lakefs_repos(_assigns), do: []

  @impl true
  def handle_event("validate", %{"destination" => destination_params}, socket) do
    changeset =
      socket.assigns.destination
      |> Ingest.Destinations.change_destination(destination_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(:type, Map.get(destination_params, "type"))
      |> assign(:lakefs_repos, Map.get(destination_params, "lakefs_repos", socket.assigns.lakefs_repos))

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"action" => action, "destination" => destination_params}, socket) do
    case action do
      "test_connection" ->
        handle_test_connection(socket, destination_params)

      "save" ->
        save_destination(socket, socket.assigns.live_action, destination_params)

      _unknown_action ->
        Logger.error("Unknown action received: #{inspect(action)}")
        {:noreply, put_flash(socket, :error, "Invalid action: #{action}")}
    end
  end

  defp handle_test_connection(socket, destination_params) do
    # Extract destination name
    destination_name = Map.get(destination_params, "name", "default-repo-name")

    # Extract lakefs_config from destination_params and ensure all required keys are present
    lakefs_config = Map.get(destination_params, "lakefs_config", %{})
    base_url = Map.get(lakefs_config, "base_url", "localhost")
    port = Map.get(lakefs_config, "port", "8000")
    ssl = Map.get(lakefs_config, "ssl", "false")

    # Call build_base_url with a fully formed map
    base_url = build_base_url(%{"base_url" => base_url, "port" => port, "ssl" => ssl})
    access_key_id = Map.get(lakefs_config, "access_key_id", "")
    secret_key = Map.get(lakefs_config, "secret_access_key", "")

    with {:ok, client} <- LakefsClient.new(base_url, access_key: access_key_id, secret_key: secret_key),
         {:ok, repos} <- LakefsClient.list_repos(client) do

      Logger.debug("LakeFS client initialized with base_url: #{base_url}")

      if Enum.any?(repos["results"], fn %{"id" => id} -> id == destination_name end) do
        Logger.info("Repository #{destination_name} already exists in LakeFS.")
        {:noreply, assign(socket, :lakefs_repos, repos)}
      else
        Logger.info("Repository #{destination_name} does not exist. Attempting to create it...")

        case Ingest.LakeFS.check_or_create_repo(client, destination_name) do
          {:ok, _response} ->
            Logger.info("Successfully created repository #{destination_name} in LakeFS.")
            case LakefsClient.list_repos(client) do
              {:ok, updated_repos} ->
                {:noreply, assign(socket, :lakefs_repos, updated_repos)}
              {:error, reason} ->
                Logger.error("Failed to re-fetch the updated list of repos. Reason: #{inspect(reason)}")
                {:noreply, put_flash(socket, :error, "Repository created, but failed to reload repositories.")}
            end

          {:error, reason} ->
            Logger.error("Failed to create repository #{destination_name}. Reason: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Failed to create repository. Please check your credentials and URL.")}
        end
      end
    else
      {:error, reason} ->
        Logger.error("Failed to connect to LakeFS. Reason: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to connect to LakeFS. Please check your credentials and URL.")}
    end
  end

  defp save_destination(socket, :new, destination_params) do
    destination_params =
      Map.put(destination_params, "classifications_allowed", collect_classifications(destination_params))

    case Map.put(destination_params, "inserted_by", socket.assigns.current_user.id)
         |> Ingest.Destinations.create_destination() do
      {:ok, destination} ->
        notify_parent({:saved, destination})
        {:noreply, socket |> put_flash(:info, "Destination created successfully") |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_destination(socket, :edit, destination_params) do
    destination_params =
      Map.put(destination_params, "classifications_allowed", collect_classifications(destination_params))
      |> Map.put("updated_by", socket.assigns.current_user.id)

    case Ingest.Destinations.update_destination(socket.assigns.destination, destination_params) do
      {:ok, destination} ->
        notify_parent({:saved, destination})
        {:noreply, socket |> put_flash(:info, "Destination updated successfully") |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset)
    assign(socket, :destination_form, form)
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

  defp build_base_url(%{"base_url" => base_url, "port" => port, "ssl" => ssl}) do
    scheme = if ssl == "true", do: "https", else: "http"
    port_part = if port && port != "", do: ":#{port}", else: ":8000"
    "#{scheme}://#{base_url}#{port_part}"
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
