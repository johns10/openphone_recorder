import Config

# Configure your database
config :discussit, Discussit.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "discussit_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :discussit, DiscussitWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "noIbBqNaEi8QILxpQ+ZQNgd1Aojgpq3SFL3a0nxEl6Mh7YVF7qR8q9/rNCWLqf89",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

config :discussit, DiscussitWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/discussit_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :discussit,
  dev_routes: true,
  signing_secret: "TGNwdWZzbjhSVmRaQ0NBZTJtN3FRdU05QkF1amd1Z1E="

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :discussit, :minio, true

config :ex_aws, :s3,
  access_key_id: "minio_key",
  secret_access_key: "minio_secret",
  scheme: "http://",
  region: "local",
  host: "127.0.0.1",
  port: 9000,
  minio_path: "data"

config :swoosh, :api_client, false
config :discussit, Discussit.Mailer, adapter: Swoosh.Adapters.Local
config :discussit, model_path: Path.expand("./priv")
