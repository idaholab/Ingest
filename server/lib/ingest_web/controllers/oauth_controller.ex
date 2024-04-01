defmodule IngestWeb.OAuthController do
  use IngestWeb, :controller

  def oauth(conn, %{"code" => code}) do
    auth_code = code
    userid = conn.assigns.current_user.id
    access_token = Ingest.OAuth.Util.get_access_token(auth_code)
    Cachex.put!(:server, "Box_Access_Token:#{userid}", access_token)
    redirect(conn, to: "http://localhost:4000/dashboard")
  end
end
