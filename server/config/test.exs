import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :argon2_elixir, t_cost: 1, m_cost: 8

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ingest, Ingest.Repo,
  database: Path.join(__DIR__, "databases/ingest"),
  journal_mode: :wal,
  auto_vacuum: :incremental,
  datetime_type: :iso8601,
  pool: Ecto.Adapters.SQL.Sandbox,
  binary_id_type: :binary,
  uuid_type: :binary,
  load_extensions: [
    "./priv/sqlite_extensions/crypto",
    "./priv/sqlite_extensions/fileio",
    "./priv/sqlite_extensions/fuzzy",
    "./priv/sqlite_extensions/math",
    "./priv/sqlite_extensions/stats",
    "./priv/sqlite_extensions/text",
    "./priv/sqlite_extensions/unicode",
    "./priv/sqlite_extensions/uuid",
    "./priv/sqlite_extensions/vec0",
    "./priv/sqlite_extensions/vsv"
  ]

config :ecto_sqlite3,
  binary_id_type: :binary,
  uuid_type: :binary

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ingest, IngestWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "XvVGGL6usjMplRva2TfagtLfayv88C/1erGcFPF8/8h+5Q5DQKSuDKj/kzgiy0SR",
  server: false

# In test we don't send emails.
config :ingest, Ingest.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :ingest, Oban, testing: :inline

config :ingest, :datahub,
  token: "",
  gms_url: "",
  url: ""

config :ingest, :lakefs,
  url: "",
  access_key: "",
  secret_access_key: ""
