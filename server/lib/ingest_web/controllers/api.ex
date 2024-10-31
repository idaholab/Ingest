defmodule IngestWeb.ApiController do
  use IngestWeb, :controller

  alias Plug.Conn
  alias Ingest.LakeFS
  alias Ingest.DataHub
  alias Ingest.Processors.FileProcessor
  alias JOSE

  def handle_merge_event(conn, _params) do
    event = conn.body_params

    resp =
      LakeFS.diff_merge(
        event,
        # the & and /arity is how we reference closures
        &FileProcessor.process_delete/3,
        &FileProcessor.process/3,
        &FileProcessor.process/3
      )

    case resp do
      {:ok, _created} -> send_resp(conn, 200, "Metadata event processed successfully")
      {:error, message} -> send_resp(conn, 500, Jason.encode!(message.body))
      _ -> send_resp(conn, 500, "Unable to process metadata event")
    end
  end

  def handle_precommit_event(conn, params) do
    # TODO: pull project name from parameters - match with project name and pull the first, active Data Request for the project
    event = conn.body_params

    resp =
      LakeFS.diff_merge(
        event,
        # the & and /arity is how we reference closures
        # TODO: replace these functions with new functions the functions should do the following:
        # on_create: We should take the email of whoever the USER is that is making this commit on LakeFS, the request from line 30 and make a new Upload record for that request (Ingest.Uploads.Upload) (do not do duplicates, so make sure it doesn't exist already)
        # on_delete: Same as above, but remove all uploads with the same name from that user for that request
        &FileProcessor.process_delete/3,
        &FileProcessor.process/3,
        &FileProcessor.process/3
      )

    case resp do
      {:ok, _created} -> send_resp(conn, 200, "Metadata event processed successfully")
      {:error, message} -> send_resp(conn, 500, Jason.encode!(message.body))
      _ -> send_resp(conn, 500, "Unable to process metadata event")
    end
  end

  def get_download_link(conn, params) do
    # we're going to pull the cookie since the JWT we need is there inside the cookie
    conn = Conn.fetch_cookies(conn)
    # JWT.peek lets us pull the token without having to have a signing key to verify
    # I'm not worried about security here because DataHub will determine finally authenticity
    # of the JWT
    token = Map.get(conn.cookies, "PLAY_SESSION", "") |> JOSE.JWT.peek()
    urn = Map.get(params, "urn", "")

    # if at any point our processes crash, like we don't get what we expect here, the
    # plug will return a 500 - so we really don't have to explicity handle every error
    {:ok, link} = DataHub.get_download_link(urn, token: token.fields["data"]["token"])

    {:ok, redirect} =
      LakeFS.presigned_download_url(
        link["endpoint"],
        link["repo"],
        "Test-Request-by-",
        link["filename"]
      )

    # we want to make sure we're passing all headers that would normally be present
    conn =
      Enum.reduce(redirect.headers, conn, fn {header, value}, acc ->
        Plug.Conn.put_resp_header(acc, header, Enum.join(value, ","))
      end)

    send_resp(conn, 302, "")
  end
end
