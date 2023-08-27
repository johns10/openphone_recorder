defmodule Discussit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        # Start the Telemetry supervisor
        DiscussitWeb.Telemetry,
        # Start the Ecto repository
        Discussit.Repo,
        # Start the PubSub system
        {Phoenix.PubSub, name: Discussit.PubSub},
        # Start Finch
        {Finch, name: Discussit.Finch},
        # Start the Endpoint (http/https)
        DiscussitWeb.Endpoint,
        {Discussit.Events.Consumer, %{count: :inf}}
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
