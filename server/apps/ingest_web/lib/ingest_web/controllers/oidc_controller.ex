defmodule IngestWeb.OidcController do
  use IngestWeb, :controller

  alias Ingest.Requests
  alias Ingest.Destinations
  alias Ingest.Accounts
  alias IngestWeb.UserAuth

  def oneid(conn, %{"code" => code}) do
    config = Application.get_env(:ingest, :openid_connect_oneid)

    with {:ok, token} <-
           Oidcc.retrieve_token(
             code,
             IngestWeb.Application.OneID,
             config[:client_id],
             config[:client_secret],
             %{redirect_uri: config[:redirect_uri]}
           ),
         {:ok, claims} <-
           Oidcc.retrieve_userinfo(
             token,
             IngestWeb.Application.OneID,
             config[:client_id],
             config[:client_secret],
             %{expected_subject: "sub"}
           ),
         user <- Accounts.get_user_by_email(claims["email"]) do
      case user do
        nil ->
          case Accounts.register_user(
                 %{
                   email: claims["email"],
                   roles: :manager,
                   identity_provider: :oidc,
                   identity_provider_id: claims["sub"]
                 },
                 :oidcc
               ) do
            {:ok, user} ->
              Destinations.backfill_shared_destinations(user)
              Requests.backfill_shared_templates(user)
              UserAuth.log_in_user(conn, user, %{})

            {:error, err} ->
              conn
              |> put_flash(:error, "unable to get register user #{err}")
              |> redirect(to: "/")
          end

        _ ->
          Accounts.update_user_identity_provider(user, %{identity_provider_id: claims["sub"]})
          UserAuth.log_in_user(conn, user, %{})
      end
    else
      {:error, {_err, _status_code, %{"error" => error}}} ->
        conn |> put_flash(:error, "unable to get user info #{error}") |> redirect(to: "/")
    end
  end

  def okta(conn, %{"code" => code}) do
    config = Application.get_env(:ingest, :openid_connect_okta)

    with {:ok, token} <-
           Oidcc.retrieve_token(
             code,
             IngestWeb.Application.Okta,
             config[:client_id],
             config[:client_secret],
             %{redirect_uri: config[:redirect_uri]}
           ),
         {:ok, claims} <-
           Oidcc.retrieve_userinfo(
             token,
             IngestWeb.Application.Okta,
             config[:client_id],
             config[:client_secret],
             %{expected_subject: "sub"}
           ),
         user <- Accounts.get_user_by_email(claims["email"]) do
      case user do
        nil ->
          case Accounts.register_user(
                 %{
                   email: claims["email"],
                   roles: :manager,
                   identity_provider: :oidc,
                   identity_provider_id: claims["sub"]
                 },
                 :oidcc
               ) do
            {:ok, user} ->
              Destinations.backfill_shared_destinations(user)
              Requests.backfill_shared_templates(user)
              UserAuth.log_in_user(conn, user, %{})

            {:error, err} ->
              conn
              |> put_flash(:error, "unable to get register user #{err}")
              |> redirect(to: "/")
          end

        _ ->
          Accounts.update_user_identity_provider(user, %{identity_provider_id: claims["sub"]})
          UserAuth.log_in_user(conn, user, %{})
      end
    else
      {:error, {_err, _status_code, %{"error" => error}}} ->
        conn |> put_flash(:error, "unable to get user info #{error}") |> redirect(to: "/")
    end
  end
end
