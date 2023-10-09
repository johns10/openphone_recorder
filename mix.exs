defmodule Discussit.MixProject do
  use Mix.Project

  def project do
    [
      app: :discussit,
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
      mod: {Discussit.Application, []},
      extra_applications: [:logger, :runtime_tools, :stripity_stripe]
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
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.1"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_view, "~> 0.19.5"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.16"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.5"},
      {:inflex, "~> 2.0.0"},
      {:uuid, "~> 1.1"},
      {:ecto_phone_number, "~> 0.4"},
      {:httpoison, "~> 2.1"},
      {:briefly, "~> 0.4"},
      {:openai, "~> 0.5.2"},
      {:decimal, "~> 2.1.1"},
      {:timex, "~> 3.0"},
      {:bodyguard, "~> 2.4"},
      {:muontrap, "~> 0.5"},
      {:gpt3_tokenizer, "~> 0.1.0"},
      {:ex_openai, "~> 1.2.1"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:flow, "~> 1.2.4"},
      {:mime, "~> 2.0.5"},
      {:retry, "~> 0.18"},
      {:stripity_stripe, "~> 2.17"},
      {:pgvector, "~> 0.2.0"},
      {:pg_ranges, git: "https://github.com/johns10/pg_ranges"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1.8", runtime: Mix.env() == :dev},
      {:minio_server, "~> 0.3.2", only: :dev},
      {:mix_test_watch, "~> 1.0", runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:floki, ">= 0.30.0", only: :test},
      {:faker, "~> 0.17", only: :test},
      {:exvcr, "~> 0.11", only: :test}
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
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
