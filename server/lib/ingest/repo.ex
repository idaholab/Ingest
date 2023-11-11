defmodule Ingest.Repo do
  use Ecto.Repo,
    otp_app: :ingest,
    adapter: Ecto.Adapters.Postgres
end
