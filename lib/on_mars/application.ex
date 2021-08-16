defmodule OnMars.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      OnMarsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: OnMars.PubSub},
      # Start the Endpoint (http/https)
      OnMarsWeb.Endpoint,
      # Start a worker by calling: OnMars.Worker.start_link(arg)
      # {OnMars.Worker, arg}
      OnMars.Rovers.Process
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OnMars.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    OnMarsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
