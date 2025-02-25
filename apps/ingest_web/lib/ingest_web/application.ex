defmodule IngestWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      IngestWeb.Telemetry,
      # Start a worker by calling: BobWeb.Worker.start_link(arg)
      # {BobWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      IngestWeb.Endpoint
    ]

    children =
      if Application.get_env(:ingest, :environment) == :prod do
        [
          Supervisor.child_spec(
            {Oidcc.ProviderConfiguration.Worker,
             %{
               issuer: Application.get_env(:ingest, :openid_connect_okta)[:issuer],
               name: __MODULE__.Okta
               # provider_configuration_opts: %{request_opts: Ingest.Utilities.httpc_opts()}
             }},
            id: :okta
          )
          | children
        ]
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IngestWeb.Supervisor]
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
