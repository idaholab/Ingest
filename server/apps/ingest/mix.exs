defmodule Ingest.MixProject do
  use Mix.Project

  def project do
    [
      app: :ingest,
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
      {:phoenix_live_view, "~> 1.0.0-rc.7", override: true},
      {:cloak_ecto, "~> 1.3.0"},
      {:req, "~> 0.5.0"},
      {:timex, "~> 3.7.11"},
      {:gen_smtp, "~> 1.2"},
      {:azure_storage, path: "../../../azure_storage"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:sweet_xml, "~> 0.7.4"},
      {:oban, "~> 2.17"},
      {:earmark, "~> 1.4"},
      {:bodyguard, "~> 2.4"},
      {:error_tracker, "~> 0.4"},
      {:explorer, "~> 0.10.0"},
      {:ecto_sqlite3_extras, "~> 1.2.2"},
      {:credo, "~> 1.7.9", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:rustler, "~> 0.35.0", override: true}
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
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["clean.db", "ecto.setup"],
      "clean.db": ["cmd rm -rf databases"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "sqlite.fetch": [
        "cmd cd priv/sqlite_extensions && ./install_sqlean.sh",
        "cmd cd priv/sqlite_extensions && curl -L https://github.com/asg017/sqlite-vec/releases/download/v0.1.1/install.sh | sh"
      ]
    ]
  end
end
