defmodule Ingest.MixProject do
  use Mix.Project

  def project do
    [
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

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:argon2_elixir, "~> 4.0"},
      {:bandit, "~> 1.5"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0-rc.6", override: true},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.17.0"},
      {:finch, "~> 0.13"},
      {:error_tracker, "~> 0.1"},
      {:telemetry_metrics, "~> 1.0.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:oidcc, "~> 3.2.3"},
      {:jose, "~> 1.11"},
      {:ecto_psql_extras, "~> 0.8"},
      {:cachex, "~> 3.6.0"},
      {:cloak_ecto, "~> 1.3.0"},
      {:req, "~> 0.5.0"},
      {:timex, "~> 3.7.11"},
      {:gen_smtp, "~> 1.2"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:azure_storage, path: "../azure_storage"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:sweet_xml, "~> 0.7.4"},
      {:oban, "~> 2.17"},
      {:backpex, "~> 0.6.0"},
      {:earmark, "~> 1.4"},
      {:bodyguard, "~> 2.4"},
      {:explorer, "~> 0.9.0"},
      {:reverse_proxy_plug, "~> 3.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "clean.db": ["cmd rm -rf databases"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "cmd cd assets && npm install"
      ],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      "sqlite.fetch": [
        "cmd cd priv/sqlite_extensions && curl -L https://github.com/asg017/sqlite-vec/releases/download/v0.1.1/install.sh | sh",
        "cmd cd priv/sqlite_extensions && sh install.sh"
      ]
    ]
  end
end
