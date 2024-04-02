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

  def get_access_token(code) do
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
    access_token
  end
end
