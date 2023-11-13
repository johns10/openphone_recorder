defmodule Discussit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start the Telemetry supervisor
    # Start the Ecto repository
    # Start the PubSub system
    # Start Finch
    # Start the Endpoint (http/https)
    children =
      [
        DiscussitWeb.Telemetry,
        Discussit.Repo,
        {Phoenix.PubSub, name: Discussit.PubSub},
        {Finch, name: Discussit.Finch},
        DiscussitWeb.Endpoint,
        {Oban, Application.fetch_env!(:discussit, Oban)}
      ] ++ children(Mix.env())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Discussit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def children(:test), do: []

  def children(:dev), do: [{MinioServer, Application.get_env(:ex_aws, :s3)} | children(:prod)]

  def children(:prod),
    do: [
      {Discussit.Events.Consumer, %{count: :inf}},
      {Discussit.Embeddings.Server, %{}},
      {Discussit.Embeddings.ModelStatus, %{}},
      {Discussit.TopicAnalyzer.Server, %{}},
      {DynamicSupervisor, strategy: :one_for_one, name: Discussit.TopicAnalyzer.StatusSupervisor},
      {Registry, keys: :unique, name: TopicAnalyzerRegistry}
    ]

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DiscussitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
