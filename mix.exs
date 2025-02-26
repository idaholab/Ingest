defmodule Ingest.MixProject do
  use Mix.Project

  def project do
    [
      name: "Ingest",
      app: :ingest,
      version: "0.1.0",
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
      mod: {Ingest.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp deps do
    [
      {:argon2_elixir, "~> 4.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:dns_cluster, "~> 0.1.1"},
      {:ecto_sql, "~> 3.12.1"},
      {:ecto_sqlite3, "~> 0.17.3"},
      {:floki, ">= 0.30.0", only: :test},
      {:swoosh, "~> 1.17.0"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:cachex, "~> 3.6.0"},
      {:cloak_ecto, "~> 1.3.0"},
      {:req, "~> 0.5.0"},
      {:timex, "~> 3.7.11"},
      {:gen_smtp, "~> 1.2"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:sweet_xml, "~> 0.7.4"},
      {:oban, "~> 2.17"},
      {:earmark, "~> 1.4"},
      {:bodyguard, "~> 2.4"},
      {:oban_web, "~> 2.11"},
      {:error_tracker, "~> 0.4"},
      {:explorer, "~> 0.10.0"},
      {:ecto_sqlite3_extras, "~> 1.2.2"},
      {:credo, "~> 1.7.9", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:rustler, "~> 0.35.0", override: true},
      {:uuid, "~> 1.1"},
      {:bandit, "~> 1.5"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.6.3"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0", override: true},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.8.2", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.4", runtime: Mix.env() == :dev},
      {:slugify, "~> 1.3"},
      {:gettext, "~> 0.20"},
      {:plug_cowboy, "~> 2.5"},
      {:oidcc, "~> 3.2.3"},
      {:jose, "~> 1.11"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:backpex, "~> 0.9.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      setup: ["deps.get", "clean.db", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["clean.db", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["clean.db", "ecto.setup"],
      "clean.db": ["cmd rm -rf config/databases"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "sqlite.fetch": [
        "cmd cd priv/sqlite_extensions && ./install_sqlean.sh",
        "cmd cd priv/sqlite_extensions && curl -L https://github.com/asg017/sqlite-vec/releases/download/v0.1.1/install.sh | sh"
      ],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "cmd cd assets && npm install"
      ],
      "assets.build": ["tailwind ingest", "esbuild ingest"],
      "assets.deploy": [
        "tailwind ingest --minify",
        "esbuild ingest --minify",
        "phx.digest"
      ]
    ]
  end
end
