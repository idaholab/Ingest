defmodule Ingest.OAuth.Util do
  def get_auth_url() do
    box_auth_creds = Application.get_env(:ingest, :box_oauth_creds)
    base_url = Keyword.get(box_auth_creds, :base_url)
    client_id = Keyword.get(box_auth_creds, :client_id)
    redirect_uri = "http://localhost:4000/box/oauth"

    auth_url =
      "#{base_url}?client_id=#{client_id}&redirect_uri=#{redirect_uri}&response_type=code"

    auth_url
  end

  def get_tokens(code) do
    box_auth_creds = Application.get_env(:ingest, :box_oauth_creds)

    auth_url = "https://api.box.com/oauth2/token"

    params = %{
      "grant_type" => "authorization_code",
      "code" => code,
      "client_id" => Keyword.get(box_auth_creds, :client_id),
      "client_secret" => Keyword.get(box_auth_creds, :client_secret)
    }

    resp =
      Req.post!(auth_url,
        form: params,
        connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
      )

    access_token = resp.body["access_token"]
    refresh_token = resp.body["refresh_token"]
    {access_token, refresh_token}
  end

  def refresh_access_token(refresh_token, current_user_id) do
    box_auth_creds = Application.get_env(:ingest, :box_oauth_creds)

    auth_url = "https://api.box.com/oauth2/token"

    headers = [
      {"content-type", "application/x-www-form-urlencoded"}
    ]

    params = %{
      "client_id" => Keyword.get(box_auth_creds, :client_id),
      "client_secret" => Keyword.get(box_auth_creds, :client_secret),
      "refresh_token" => refresh_token,
      "grant_type" => "refresh_token"
    }

    resp =
      Req.post!(auth_url,
        headers: headers,
        form: params,
        connect_options: [transport_opts: [cacertfile: "/etc/ssl/certs/CAINLROOT.cer"]]
      )

    case resp do
      %{status: 200, body: %{"access_token" => access_token, "refresh_token" => refresh_token}} ->
        Cachex.put!(:server, "Box_Tokens:#{current_user_id}", {access_token, refresh_token})

      %{status: 400} ->
        {:error, "Bad Request"}

      %{status: 401} ->
        {:error, "Unauthorized"}

      %{status: 500} ->
        {:error, "Internal Server Error"}

      _ ->
        {:error, "Unknown Error"}
    end
  end
end
