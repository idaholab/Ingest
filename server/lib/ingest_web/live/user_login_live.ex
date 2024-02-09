defmodule IngestWeb.UserLoginLive do
  use IngestWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        <img class="mx-auto h-10 w-auto" src="/images/logo.png" alt="Your Company" />
        Sign in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
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
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button
            phx-disable-with="Signing in..."
            class="flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Sign in <span aria-hidden="true">→</span>
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
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
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
      {:error, :provider_not_ready} ->
        {:noreply, socket}
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

          final_url = build_url(Enum.join(redirect_uri, ""))
          # final_url = with {:ok, uri} <- URI.new(Enum.join(redirect_uri, "")) do
          #       query = URI.decode_query(uri.query)
          #       query = query |> Enum.reject(fn {k, v} -> String.contains(k, "redirect_uri") end)
          #             |> Enum.reject(fn {k, v} -> String.contains(k, "client_id") end)
          #       encoded_query = query |> URI.encode_query()

          #       my_url = "#{uri.scheme}://#{uri.host}#{uri.path}?#{encoded_query}"

          #       # my_url = Enum.join(redirect_uri, "")
          #       # my_url = Regex.replace(~r/client_id=.+&*/, my_url, "")
          #       # my_url = Regex.replace(~r/redirect_uri=.+&*/, my_url, "")
          #       # my_url = String.trim(my_url, "&")
          #       IO.puts my_url

          #       my_url
          # else { :error, :provider_not_ready } ->
          #     redirect_uri
          # end
      {:noreply, socket |> redirect(external: final_url)}
    else
      {:error, :provider_not_ready} ->
        {:noreply, socket}
    end
  end

  def build_url(raw_uri) do
    raw_uri
  #   with {:ok, uri} <- URI.new(raw_uri) do
  #     query = URI.decode_query(uri.query)
  #     query = query |> Enum.reject(fn {k, v} -> String.contains?(k, "redirect_uri") end)
  #           |> Enum.reject(fn {k, v} -> String.contains?(k, "client_id") end)
  #     encoded_query = query |> URI.encode_query()

  #     my_url = "#{uri.scheme}://#{uri.host}#{uri.path}?#{encoded_query}?state=test"

  #     # my_url = Enum.join(redirect_uri, "")
  #     # my_url = Regex.replace(~r/client_id=.+&*/, my_url, "")
  #     # my_url = Regex.replace(~r/redirect_uri=.+&*/, my_url, "")
  #     # my_url = String.trim(my_url, "&")
  #     IO.puts my_url

  #     my_url
  #   else
  #     {:error, :not_found} -> raw_uri
  #   end
  # end
  end
end
