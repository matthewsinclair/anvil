import Config
config :anvil, Oban, testing: :manual
config :anvil, token_signing_secret: "haIVOv7bN0CFlsVKoaQ4MWVsQW0Liy7e"
config :bcrypt_elixir, log_rounds: 1
config :ash, policies: [show_policy_breakdowns?: true]

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :anvil, Anvil.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "anvil_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :anvil, AnvilWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "eFdKKB++8pYEUhxLMpPC4NwnMige0TXJ5/qr/UYEHc0bWlipvwkPyA98j7zh1hCZ",
  server: false

# In test we don't send emails
config :anvil, Anvil.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# PhoenixTest
# See: https://hexdocs.pm/phoenix_test/PhoenixTest.html#module-configuration
config :phoenix_test, :endpoint, AnvilWeb.Endpoint
