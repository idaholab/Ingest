defmodule IngestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ingest

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_ingest_key",
    signing_salt: "HLm+jAwf",
    secure: true,
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # ClientSocket handles communication with the connected high speed transfer clients
  socket("/client", IngestWeb.ClientSocket,
    websocket: true,
    longpoll: false
  )

  # UserSocket handles notifications
  socket("/socket", IngestWeb.UserSocket,
    websocket: true,
    longpoll: false
  )

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :ingest,
    gzip: false,
    only: IngestWeb.static_paths()
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :ingest)
  end

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, {:multipart, length: 100_000_000_000_000_000_000_000_000_000}, :json],
    pass: ["*/*"],
    length: 100_000_000_000_000_000_000_000_000_000,
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(IngestWeb.Router)
end
