defmodule Discussit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        DiscussitWeb.Telemetry,
        Discussit.Repo,
        {Phoenix.PubSub, name: Discussit.PubSub},
        {Finch, name: Discussit.Finch},
        DiscussitWeb.Endpoint,
        {Oban, Application.fetch_env!(:discussit, Oban)},
        {Discussit.Events.Consumer, %{count: :inf}},
        # {Discussit.Embeddings.Server, %{}},
        {Discussit.Embeddings.ModelStatus, %{}},
        {DynamicSupervisor, strategy: :one_for_one, name: Discussit.StatusSupervisor},
        {Registry, keys: :unique, name: Discussit.StatusRegistry}
      ]
      |> minio()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Discussit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DiscussitWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def minio(children) do
    case Application.get_env(:discussit, :minio, nil) do
      nil -> children
      true -> children ++ [{MinioServer, Application.get_env(:ex_aws, :s3)}]
    end
  end
end
