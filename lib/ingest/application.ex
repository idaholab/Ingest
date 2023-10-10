defmodule Ingest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      IngestWeb.Telemetry,
      # Start the Ecto repository
      Ingest.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ingest.PubSub},
      # Start Finch
      {Finch, name: Ingest.Finch},
      # Start the Endpoint (http/https)
      IngestWeb.Endpoint
      # Start a worker by calling: Ingest.Worker.start_link(arg)
      # {Ingest.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ingest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IngestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
