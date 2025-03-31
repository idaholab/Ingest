defmodule IngestWeb.UserSettingsLive do
  use IngestWeb, :live_view

  alias Ingest.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-center">
        Account Settings
        <:subtitle>Manage your account email address and password settings</:subtitle>
      </.header>
    </div>
    <div class="space-y-12 divide-y">
      <div class="flex flex-col justify-center items-center">
        <!-- Email Section -->
        <div>
          <.header>Current Email: {@current_user.email}</.header>
        </div>
        <div id="email-form-wrap" class="hidden flex justify-center items-center">
          <.simple_form
            :if={@current_user.identity_provider in [:internal]}
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input field={@email_form[:email]} type="email" label="Email" required />
            <.input
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label="Current password"
              value={@email_form_current_password}
              required
            />
            <:actions>
              <.button class="flex justify-center items-center" phx-disable-with="Changing...">
                Confirm Email Change
              </.button>
            </:actions>
          </.simple_form>
          <div class="mt-2">
            <button
              id="cancel_email_change"
              phx-click={toggle_form("#email-form-wrap", "#show_email_change")}
              class="btn"
            >
              Cancel Email Change
            </button>
          </div>
        </div>
        <div class="flex justify-center items-center">
          <button
            id="show_email_change"
            phx-click={toggle_form("#email-form-wrap", "#show_email_change")}
            class="btn"
          >
            Change Email
          </button>
        </div>
      </div>
      
    <!-- Password Form Section -->
      <div class="flex flex-col justify-center items-center">
        <div id="password-form-wrap" class="hidden flex justify-center items-center">
          <.simple_form
            :if={@current_user.identity_provider in [:internal]}
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Current password"
              id="current_password_for_password"
              value={@current_password}
              required
            />
            <.input
              field={@password_form[:email]}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <.input field={@password_form[:password]} type="password" label="New password" required />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
            />
            <:actions>
              <.button phx-disable-with="Changing...">Confirm Password Change</.button>
            </:actions>
          </.simple_form>
          <div class="mt-2">
            <button
              class="btn"
              phx-click={toggle_form("#password-form-wrap", "#show_password_change")}
            >
              Cancel Password Change
            </button>
          </div>
        </div>
      </div>
      <div class="flex justify-center items-center pt-5">
        <button
          id="show_password_change"
          phx-click={toggle_form("#password-form-wrap", "#show_password_change")}
          class="btn"
        >
          Change Password
        </button>
      </div>
      <!-- End Form -->

        <!-- Access Key Section -->
      <div class="px-4 sm:px-6 lg:px-8 pt-10">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-gray-900">Personal Access Keys</h1>
            <p class="mt-2 text-sm text-gray-700">
              A list of your personal access keys. These keys allow you to upload files using either S3 tooling or Azure Blob Storage tooling.
            </p>
          </div>

          <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
            <div class="mt-6">
              <.link patch={~p"/users/settings/new_key"}>
                <button
                  type="button"
                  class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                >
                  <.icon name="hero-plus" /> New Access Key
                </button>
              </.link>
            </div>
          </div>
        </div>
        <div class="mt-8 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <.table id="personal_keys" rows={@streams.keys}>
                <:col :let={{_id, key}} label="Key">{key.access_key}</:col>
                <:col :let={{_id, key}} label="Expiration">
                  {"#{key.expires.day}-#{key.expires.month}-#{key.expires.year}"}
                </:col>

                <:action :let={{id, key}}>
                  <.link
                    class="text-red-600 hover:text-red-900"
                    phx-click={
                      JS.push("delete_key", value: %{id: key.access_key})
                      |> hide("##{id}")
                    }
                    data-confirm="Are you sure?"
                  >
                    Delete
                  </.link>
                </:action>
              </.table>
            </div>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action in [:new_key]}
        id="new_key_modal"
        show
        on_cancel={JS.patch(~p"/users/settings")}
      >
        <.live_component
          live_action={@live_action}
          module={IngestWeb.LiveComponents.AccessKeyForm}
          id="keys-modal-component"
          current_user={@current_user}
          patch={~p"/users/settings"}
        />
      </.modal>
    </div>
    """
  end

  defp toggle_form(form_id, show_button_id) do
    JS.toggle(to: form_id) |> JS.toggle(to: show_button_id)
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> stream_configure(:keys, dom_id: &"#{&1.access_key}")
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:section, "settings")

    {:ok, socket, layout: {IngestWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    keys = Accounts.list_user_keys(socket.assigns.current_user)

    {:noreply,
     socket
     |> stream(:keys, keys)}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  @impl true
  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl true
  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  @impl true
  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_key", %{"id" => id}, socket) do
    Accounts.delete_user_keys(Accounts.get_user_key!(socket.assigns.current_user, id))

    {:noreply,
     socket
     |> put_flash(:info, "Successfully deleted access key.")
     |> push_navigate(to: ~p"/users/settings")}
  end
end
