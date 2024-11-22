defmodule Ingest.Repo do
  use Ecto.Repo,
    otp_app: :ingest,
    adapter: Ecto.Adapters.SQLite3
end
