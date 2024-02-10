defmodule IngestWeb.OidcController do
  use IngestWeb, :controller

  alias Ingest.Accounts
  alias IngestWeb.UserAuth

  def oneid(conn, %{"code" => code}) do
    config = Application.get_env(:ingest, :openid_connect_oneid)

    with {:ok, token} <-
           Oidcc.retrieve_token(
             code,
             Ingest.Application.OneID,
             config[:client_id],
             config[:client_secret],
             %{redirect_uri: config[:redirect_uri]}
           ) do
      with {:ok, claims} <-
             Oidcc.retrieve_userinfo(
               token,
               Ingest.Application.OneID,
               config[:client_id],
               config[:client_secret],
               %{expected_subject: "sub"}
             ) do
        user = Accounts.get_user_by_email(claims["email"])

        case user do
          nil ->
            with {:ok, user} <- Accounts.register_user(%{email: claims["email"]}, :oidcc) do
              UserAuth.log_in_user(conn, user, %{})
            else
              {:error, err} ->
                conn
                |> put_flash(:error, "unable to get register user #{err}")
                |> redirect(to: "/")
            end

          _ ->
            UserAuth.log_in_user(conn, user, %{})
        end
      else
        {:error, {_err, _status_code, %{"error" => error}}} ->
          conn |> put_flash(:error, "unable to get user info #{error}") |> redirect(to: "/")
      end
    else
      {:error, {_err, _status_code, %{"error" => error}}} ->
        conn
        |> put_flash(:error, "unable to get authorization token #{error}")
        |> redirect(to: "/")
    end
  end

  def okta(conn, %{"code" => code}) do
    config = Application.get_env(:ingest, :openid_connect_okta)

    with {:ok, token} <-
           Oidcc.retrieve_token(
             code,
             Ingest.Application.Okta,
             config[:client_id],
             config[:client_secret],
             %{redirect_uri: config[:redirect_uri]}
           ) do
      with {:ok, claims} <-
             Oidcc.retrieve_userinfo(
               token,
               Ingest.Application.Okta,
               config[:client_id],
               config[:client_secret],
               %{expected_subject: "sub"}
             ) do
        user = Accounts.get_user_by_email(claims["email"])

        case user do
          nil ->
            with {:ok, user} <- Accounts.register_user(%{email: claims["email"]}, :oidcc) do
              UserAuth.log_in_user(conn, user, %{})
            else
              {:error, err} ->
                conn
                |> put_flash(:error, "unable to get register user #{err}")
                |> redirect(to: "/")
            end

          _ ->
            UserAuth.log_in_user(conn, user, %{})
        end
      else
        {:error, {_err, _status_code, %{"error" => error}}} ->
          conn |> put_flash(:error, "unable to get user info #{error}") |> redirect(to: "/")
      end
    else
      {:error, {_err, _status_code, %{"error" => error}}} ->
        conn
        |> put_flash(:error, "unable to get authorization token #{error}")
        |> redirect(to: "/")
    end
  end
end
