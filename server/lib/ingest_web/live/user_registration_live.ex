defmodule IngestWeb.UserRegistrationLive do
  use IngestWeb, :live_view

  alias Ingest.Accounts
  alias Ingest.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        <img class="mx-auto h-10 w-auto" src="/images/logo.png" alt="Your Company" />
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input
          field={@form[:email]}
          type="email"
          label="Email"
          required
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
        />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          required
          class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
        />

        <:actions>
          <.button
            phx-disable-with="Creating account..."
            class="flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Create an account
          </.button>
        </:actions>
      </.simple_form>

      <div>
        <div class="relative mt-10">
          <div class="absolute inset-0 flex items-center" aria-hidden="true">
            <div class="w-full border-t border-gray-200"></div>
          </div>
          <div class="relative flex justify-center text-sm font-medium leading-6">
            <span class="bg-white px-6 text-gray-900">Or continue with</span>
          </div>
        </div>

        <div class="mt-6 grid grid-cols-2 gap-4">
          <button phx-click="login_oneid">
            <img src="/images/oneid_logo.png" />
          </button>

          <button phx-click="login_okta">
            <img src="/images/inllogo.png" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("login_oneid", _params, socket) do
    config = Application.get_env(:ingest, :openid_connect_oneid)

    with {:ok, redirect_uri} <-
           Oidcc.create_redirect_url(
             Ingest.Application.OneID,
             config[:client_id],
             config[:client_secret],
             %{
               redirect_uri: config[:redirect_uri],
               scopes: [:openid, :email, :profile]
             }
           ) do
      {:noreply, socket |> redirect(external: Enum.join(redirect_uri, ""))}
    else
      {:error, message} ->
        {:noreply, socket |> put_flash(:error, message)}
    end
  end

  def handle_event("login_okta", _params, socket) do
    config = Application.get_env(:ingest, :openid_connect_okta)

    with {:ok, redirect_uri} <-
           Oidcc.create_redirect_url(
             Ingest.Application.Okta,
             config[:client_id],
             config[:client_secret],
             %{
               redirect_uri: config[:redirect_uri],
               scopes: [:openid, :email, :profile]
             }
           ) do
      {:noreply, socket |> redirect(external: Enum.join(redirect_uri, ""))}
    else
      {:error, message} ->
        {:noreply, socket |> put_flash(:error, message)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
