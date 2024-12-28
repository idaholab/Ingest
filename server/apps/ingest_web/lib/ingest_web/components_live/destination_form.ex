defmodule IngestWeb.LiveComponents.DestinationForm do
  @moduledoc """
  Destination Form is the form for creating/editing Destinations
  """
  alias Ingest.Destinations
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
                  Visibility
                </.label>
                <p class="text-xs">
                  Controls whether others can see and request upload access to your destination.
                </p>

                <.input
                  type="select"
                  field={@destination_form[:visibility]}
                  options={[
                    {"Private", :private},
                    {"Public", :public}
                  ]}
                />
                <p class="text-xs">
                  You will still be able to share your destination with others regardless of visibility
                </p>
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
                  <.input
                    type="password"
                    placeholder="secret not shown"
                    field={config[:access_key_id]}
                  />

                  <.label for="status-select">
                    Secret Access Key
                  </.label>
                  <.input
                    type="password"
                    placeholder="secret not shown"
                    field={config[:secret_access_key]}
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
              <.inputs_for :let={config} field={@destination_form[:lakefs_config]}>
                <div class="sm:col-span-3">
                  <.label for="status-select">
                    Access Key ID
                  </.label>
                  <.input
                    type="password"
                    placeholder="secret not shown"
                    field={config[:access_key_id]}
                  />
                </div>

                <div class="sm:col-span-3">
                  <.label for="status-select">
                    Secret Access Key
                  </.label>
                  <.input
                    type="password"
                    placeholder="secret not shown"
                    field={config[:secret_access_key]}
                  />
                </div>

                <div class="col-span-3">
                  <.label for="status-select">
                    URL
                  </.label>
                  <.input type="text" field={config[:base_url]} />
                  <p class="text-xs">
                    Leave the trailing / off the url.
                  </p>
                </div>

                <div class="col-span-3">
                  <.label for="status-select">
                    Port
                  </.label>
                  <.input type="text" field={config[:port]} />
                  <p class="text-xs">
                    When in doubt, leave blank.
                  </p>
                </div>

                <div class="col-span-3">
                  <.label for="status-select">
                    SSL
                  </.label>
                  <.input type="checkbox" field={config[:ssl]} />
                  <p class="text-xs">
                    When in doubt, enable this setting.
                  </p>
                </div>

                <div class="col-span-3">
                  <.label for="status-select">
                    Integrated Metadata
                  </.label>
                  <.input type="checkbox" field={config[:integrated_metadata]} />
                  <p class="text-xs">
                    Whether or not to use this destination's type native method for storing metadata.
                  </p>
                </div>

                <div class="sm:col-span-3">
                  <.label for="status-select">
                    Repository Name
                  </.label>
                  <.input
                    type="text"
                    field={config[:repository]}
                    phx-change="repo_name_change"
                    phx-target={@myself}
                  />
                  <p :if={@slug_repo_name} class="text py-2">
                    <b>URL Safe Repository Name:</b> {@slug_repo_name}
                  </p>
                </div>

                <div class="sm:col-span-3">
                  <.label for="status-select">
                    Root Storage Namespace
                  </.label>
                  <.input type="text" field={config[:storage_namespace]} />
                </div>

                <div class="col-span-3">
                  <.label for="status-select">
                    Create Repository (if does not exist)
                  </.label>
                  <.input type="checkbox" field={config[:upsert_repository]} />
                  <p class="text-xs">
                    Whether or not to create the repository if it does not exist.
                  </p>
                </div>
              </.inputs_for>
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
                  <.input
                    type="password"
                    placeholder="secret not shown"
                    field={config[:account_name]}
                  />
                  <p class="text-xs">
                    This field is stored in an encrypted state and will not be made available to other users of the destination
                  </p>

                  <.label for="status-select">
                    Account Key
                  </.label>
                  <.input type="password" placeholder="secret not shown" field={config[:account_key]} />
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
    changeset = Ingest.Destinations.change_destination(destination)

    {:ok,
     socket
     |> assign(:type, Atom.to_string(destination.type))
     |> assign(assigns)
     |> assign(:slug_repo_name, nil)
     |> assign(:lakefs_repos, [])
     |> assign(:destination_id, destination.id)
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
        destination =
          if socket.assigns.destination_id do
            Destinations.get_destination(socket.assigns.destination_id)
          else
            nil
          end

        client =
          if destination && destination.type == :lakefs do
            Ingest.LakeFS.new!(
              %URI{
                host: destination.lakefs_config.base_url,
                scheme:
                  if(destination.lakefs_config.ssl,
                    do: "https",
                    else: "http"
                  ),
                port: destination.lakefs_config.port
              },
              access_key: destination.lakefs_config.access_key_id,
              secret_access_key: destination.lakefs_config.secret_access_key,
              port: destination.lakefs_config.port,
              ssl: destination.lakefs_config.ssl
            )
          else
            Ingest.LakeFS.new!(
              %URI{
                host: destination_params["lakefs_config"]["base_url"],
                scheme:
                  if(destination_params["lakefs_config"]["ssl"] == "true",
                    do: "https",
                    else: "http"
                  ),
                port: destination_params["lakefs_config"]["port"]
              },
              access_key: destination_params["lakefs_config"]["access_key_id"],
              secret_access_key: destination_params["lakefs_config"]["secret_access_key"]
            )
          end

        {:ok, repos} = Ingest.LakeFS.list_repos(client)

        {:noreply,
         socket
         |> assign(:lakefs_repos, repos)}
    end
  end

  @impl true
  def handle_event("repo_name_change", params, socket) do
    {:noreply,
     socket
     |> assign(
       :slug_repo_name,
       Slug.slugify(Map.get(params["destination"]["lakefs_config"], "repository", ""))
     )}
  end

  defp save_destination(socket, :edit, destination_params) do
    destination_params =
      Map.put(
        destination_params,
        "classifications_allowed",
        collect_classifications(destination_params)
      )

    with :ok <-
           Bodyguard.permit(
             Ingest.Destinations.Destination,
             :update_destination,
             socket.assigns.current_user,
             socket.assigns.destination
           ),
         {:ok, destination} <-
           Ingest.Destinations.update_destination(socket.assigns.destination, destination_params) do
      notify_parent({:saved, destination})

      %{destination_id: socket.assigns.destination.id}
      |> Ingest.Workers.Destination.new()
      |> Oban.insert()

      {:noreply,
       socket
       |> put_flash(:info, "Destination updated successfully")
       |> push_patch(to: socket.assigns.patch)}
    else
      _ -> {:noreply, assign_form(socket, socket.assigns.destination)}
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
