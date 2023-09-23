import Config

if System.get_env("PHX_SERVER") do
  config :discussit, DiscussitWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :discussit, Discussit.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :discussit, DiscussitWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :discussit, bucket: System.get_env("BUCKET")
  config :openai, api_key: System.get_env("OPENAI_API_KEY")
  config :ex_openai, api_key: System.get_env("OPENAI_API_KEY")
  config :discussit, aai_api_key: System.get_env("AAI_API_KEY")
  config :stripity_stripe, api_key: System.get_env("STRIPE_SECRET")
  config :discussit, stripe_public_key: System.get_env("STRIPE_PUBLIC_KEY")

  config :sample, Discussit.Mailer,
    adapter: Swoosh.Adapters.AmazonSES,
    region: "us-east-2",
    access_key: System.get_env("AWS_ACCESS_KEY_ID"),
    secret: System.get_env("AWS_SECRET_ACCESS_KEY")
end
