defmodule OpenphoneRecorder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      OpenphoneRecorderWeb.Telemetry,
      # Start the Ecto repository
      OpenphoneRecorder.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: OpenphoneRecorder.PubSub},
      # Start Finch
      {Finch, name: OpenphoneRecorder.Finch},
      # Start the Endpoint (http/https)
      OpenphoneRecorderWeb.Endpoint,
      {OpenphoneRecorder.Events.Consumer, %{delay: 100}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OpenphoneRecorder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OpenphoneRecorderWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
