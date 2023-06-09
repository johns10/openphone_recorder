import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :openphone_recorder, OpenphoneRecorder.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "openphone_recorder_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :openphone_recorder, OpenphoneRecorderWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "xOaZE2kj9Pkx3KNbz5Vqx/MQy4luXhgPtc69yFb49HDUeNhXmqRv1xxx7WN7mMVO",
  server: false

# In test we don't send emails.
config :openphone_recorder, OpenphoneRecorder.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable dev routes for dashboard and mailbox
config :openphone_recorder,
  dev_routes: true,
  signing_secret: "TGNwdWZzbjhSVmRaQ0NBZTJtN3FRdU05QkF1amd1Z1E="

config :exvcr,
  global_mock: true

config :openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  http_options: [recv_timeout: 10 * 60 * 1000]
