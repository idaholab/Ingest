#:public_key.cacerts_load("/Users/venethongkha1/cspca.llnl.gov.pem")

defmodule IngestWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :ingest_web,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {IngestWeb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:argon2_elixir, "~> 4.0"},
      {:bandit, "~> 1.5"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.6.3"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0-rc.7", override: true},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.8.2", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.4", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.17.0"},
      {:finch, "~> 0.13"},
      {:error_tracker, "~> 0.4"},
      {:telemetry_metrics, "~> 1.0.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:oidcc, "~> 3.2.3"},
      {:jose, "~> 1.11"},
      {:req, "~> 0.5.0"},
      {:timex, "~> 3.7.11"},
      {:gen_smtp, "~> 1.2"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:sweet_xml, "~> 0.7.4"},
      {:backpex, "~> 0.6.0"},
      {:earmark, "~> 1.4"},
      {:bodyguard, "~> 2.4"},
      {:explorer, "~> 0.10.0"},
      {:rustler, "~> 0.35.0", override: true},
      {:ecto_sqlite3_extras, "~> 1.2.2"},
      {:ingest, in_umbrella: true},
      {:credo, "~> 1.7.9", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "cmd cd assets && npm install"
      ],
      "assets.build": ["tailwind ingest_web", "esbuild ingest_web"],
      "assets.deploy": [
        "tailwind ingest_web --minify",
        "esbuild ingest_web --minify",
        "phx.digest"
      ]
    ]
  end
end
