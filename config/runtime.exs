import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/ingest start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :ingest, IngestWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_path =
    System.get_env(
      "DATABASE_PATH",
      System.user_home() |> Path.join(".ingest") |> Path.join("ingest")
    )

  _maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :ingest, Ingest.Repo,
    database: database_path,
    journal_mode: :wal,
    auto_vacuum: :incremental,
    datetime_type: :iso8601,
    binary_id_type: :binary,
    uuid_type: :binary,
    load_extensions: [
      "/sqlite_extensions/crypto",
      "/sqlite_extensions/fileio",
      "/sqlite_extensions/fuzzy",
      "/sqlite_extensions/math",
      "/sqlite_extensions/stats",
      "/sqlite_extensions/text",
      "/sqlite_extensions/unicode",
      "/sqlite_extensions/uuid",
      "/sqlite_extensions/vec0",
      "/sqlite_extensions/vsv"
    ]

  config :ecto_sqlite3,
    binary_id_type: :string,
    uuid_type: :string

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :ingest, IngestWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :ingest, :openid_connect_okta,
    issuer: System.get_env("OKTA_ISSUER"),
    client_id: System.get_env("OKTA_CLIENT_ID"),
    client_secret: System.get_env("OKTA_CLIENT_SECRET"),
    redirect_uri: "https://#{System.get_env("PHX_HOST")}/users/log_in/okta",
    response_type: "code",
    scope: "openid email profile",
    ca_cert: "/etc/ssl/certs/CAINLROOT.cer"

  # Hide the main login form and force users to use OneID or other OIDC provider
  config :ingest, :hide_public_login, System.get_env("HIDE_PUBLIC_LOGIN")

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :ingest, IngestWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :ingest, IngestWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :ingest, Ingest.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  config :ingest, Ingest.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: System.get_env("SMTP_RELAY"),
    tls: System.get_env("SMTP_TLS")

  config :ingest, :datahub,
    token: System.get_env("DATAHUB_TOKEN"),
    gms_url: System.get_env("DATAHUB_GMS_URL"),
    url: System.get_env("DATAHUB_URL")

  config :ingest, :lakefs,
    url: System.get_env("LAKEFS_URL"),
    access_key: System.get_env("LAKEFS_ACCESS_KEY"),
    secret_access_key: System.get_env("LAKEFS_SECRET_ACCESS_KEY")
end
