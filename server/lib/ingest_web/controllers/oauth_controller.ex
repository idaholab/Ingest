defmodule IngestWeb.OAuthController do
  use IngestWeb, :controller

  def oauth(conn, %{"code" => code}) do
    auth_code = code
    userid = conn.assigns.current_user.id

    case {auth_code, userid} do
      {nil, _} ->
        redirect(conn, to: ~p"/dashboard")

      {_, nil} ->
        redirect(conn, to: ~p"/dashboard")

      _ ->
        {access_token, refresh_token} = Ingest.OAuth.Box.get_tokens(auth_code)
        Cachex.put!(:server, "Box_Tokens:#{userid}", {access_token, refresh_token})
        redirect(conn, to: ~p"/dashboard")
    end
  end
end