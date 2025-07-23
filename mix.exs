defmodule Anvil.MixProject do
  use Mix.Project

  def project do
    [
      app: :anvil,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
      consolidate_protocols: Mix.env() != :dev
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Anvil.Application, []},
      extra_applications: [:logger, :runtime_tools],
      start_phases: [
        validate_directories: [],
        load_schemas: [],
        initialize_registries: [],
        register_config_callbacks: [],
        load_config: []
      ]
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
      # Phoenix
      {:phoenix, "~> 1.8.0-rc.4", override: true},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.20"},
      {:phoenix_html, "~> 4.2", override: true},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_view, "~> 1.1.0-rc.0", override: true},
      {:floki, "~> 0.37"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:lucide_icons, "~> 2.0"},
      {:swoosh, "~> 1.19"},
      {:finch, "~> 0.19"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.2"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.2"},
      {:bandit, "~> 1.6"},
      {:nimble_csv, "~> 1.2"},
      # phoenix_test 0.7 has issues with Phoenix RC versions
      # Remove or replace with a working version when needed
      # {:phoenix_test, "~> 0.7", only: :test, runtime: false, override: true},
      {:live_debugger, "~> 0.3", only: [:dev]},
      {:phoenix_storybook, "~> 0.8"},
      {:lazy_html, ">= 0.1.0", only: :test},

      # Ash
      {:ash, "~> 3.5", override: true},
      {:ash_admin, "~> 0.13"},
      {:ash_authentication, "~> 4.8"},
      {:ash_authentication_phoenix, "~> 2.7"},
      {:ash_graphql, "~> 1.7"},
      {:ash_json_api, "~> 1.4"},
      {:ash_oban, "~> 0.4"},
      {:ash_ops, "~> 0.2"},
      {:ash_phoenix, "~> 2.3"},
      {:ash_postgres, "~> 2.5"},
      {:ash_state_machine, "~> 0.2"},
      {:ash_csv, "~> 0.9"},
      {:ash_ai, "~> 0.2"},
      {:bcrypt_elixir, "~> 3.3"},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:picosat_elixir, "~> 0.2"},
      {:sourceror, "~> 1.10", only: [:dev, :test]},
      {:oban, "~> 2.19"},
      {:oban_web, "~> 2.0"},

      # LLMs
      {:usage_rules, "~> 0.1", only: [:dev]},

      # Arca
      {:arca_config, github: "matthewsinclair/arca-config", branch: "main", override: true},
      {:arca_cli, github: "matthewsinclair/arca-cli", branch: "main", override: true},
      {:arca_dbutils, github: "matthewsinclair/arca-dbutils", branch: "main", override: true},

      # ASCII table formatting
      {:table_rex, "~> 4.1"},
      {:owl, "~> 0.12"},

      # Markdown processing
      {:earmark, "~> 1.5.0-pre1"},

      # Logging
      {:logger_file_backend, "~> 0.0.14"},

      # Environment management
      {:dotenv, "~> 3.0", only: [:dev, :test], runtime: false},

      # Other
      {:faker, "~> 0.18"},
      {:absinthe_phoenix, "~> 2.0"},
      {:mishka_chelekom, "~> 0.0", only: :dev},
      {:req, "~> 0.5"},

      # MCP: Tidewave for Phoenix
      {:tidewave, "~> 0.2", only: [:dev, :test]},

      # Code quality
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # OTP28 compatibility - using official releases with fixes
      # OTP28 fix in 0.6.5, overriding ash_json_api's ~> 0.4 requirement
      {:json_xema, "~> 0.6.5", override: true},
      # OTP28 fix in 3.21.4
      {:open_api_spex, "~> 3.21", override: true}
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
      setup: ["deps.get", "ash.setup", "assets.setup", "assets.build", "run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ash.setup --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind anvil", "esbuild anvil"],
      "assets.deploy": [
        "tailwind anvil --minify",
        "esbuild anvil --minify",
        "phx.digest"
      ]
    ]
  end
end
