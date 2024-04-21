# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :discussit,
  ecto_repos: [Discussit.Repo]

config :discussit, Discussit.Repo, types: Discussit.PostgrexTypes

# Configures the endpoint
config :discussit, DiscussitWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: DiscussitWeb.ErrorHTML, json: DiscussitWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Discussit.PubSub,
  live_view: [signing_salt: "yIQeoACI"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :discussit, Discussit.Mailer,
  adapter: Swoosh.Adapters.Brevo,
  api_key: System.get_env("BREVO_API_KEY")

config :swoosh,
  api_client: Swoosh.ApiClient.Finch,
  finch_name: Discussit.Finch

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2019 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  http_options: [recv_timeout: 10 * 60 * 1000]

config :ex_openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  http_options: [recv_timeout: 10 * 60 * 1000]

config :ex_aws,
  region: "us-east-2"

config :discussit, bucket: "discussit"

config :mime, :types, %{
  "audio/mp4" => ["m4a"]
}

config :discussit, aai_api_key: System.get_env("AAI_API_KEY")
config :discussit, stripe_public_key: System.get_env("STRIPE_PUBLIC_KEY")
config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET")

config :discussit, Oban,
  queues: [conversation_summarizer: 100, media: 1, embeddings: 1, events: 1],
  repo: Discussit.Repo,
  plugins: [{Oban.Plugins.Pruner, max_age: 300}]

config :nx, default_backend: EXLA.Backend

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
