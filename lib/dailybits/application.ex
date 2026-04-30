defmodule Dailybits.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DailybitsWeb.Telemetry,
      Dailybits.Repo,
      {DNSCluster, query: Application.get_env(:dailybits, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:dailybits, Oban)},
      {Phoenix.PubSub, name: Dailybits.PubSub},
      {Dailybits.Mcp.Server, transport: :streamable_http},
      # Start a worker by calling: Dailybits.Worker.start_link(arg)
      # {Dailybits.Worker, arg},
      # Start to serve requests, typically the last entry
      DailybitsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dailybits.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DailybitsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
