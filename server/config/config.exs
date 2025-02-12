# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ingest,
  ecto_repos: [Ingest.Repo]

config :ingest, :generators,
  migration: true,
  binary_id: true

# Configures the endpoint
config :ingest_web, IngestWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: IngestWeb.ErrorHTML, json: IngestWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Ingest.PubSub,
  live_view: [signing_salt: "Rca2A0wd"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ingest, Ingest.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ingest_web: [
    args:
      ~w(js/app.js --bundle --target=esnext --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/ingest_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
  # ca_cert: "PATH TO CA CERTS"

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  ingest_web: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/ingest_web/assets", __DIR__)
  ]
  # ca_cert: "PATH TO CA CERTS"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ingest, Ingest.Vault,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      # CHANGE THIS KEY IN PRODUCTION, THIS HAS BEEN COMMITTED AND IS A TEST KEY ONLY
      tag: "AES.GCM.V1", key: Base.decode64!("YN8t8i7eqbjrWKNdIdotnpST7DEKh/2+NWjcKdPoLus=")
    }
  ]

config :ingest, Oban,
  engine: Oban.Engines.Lite,
  queues: [default: 10, metadata: 10, destinations: 5],
  repo: Ingest.Repo

config :error_tracker,
  repo: Ingest.Repo,
  otp_app: :ingest_web

# classification acronyms - NOTE: if you change these, ensure that you're not removing any \
# which are currently in use, or the system will break
config :ingest, :data_classifications, [:ouo, :pii, :ec, :ucni, :cui, :uur]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
