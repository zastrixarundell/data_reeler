defmodule DataReeler.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DataReelerWeb.Telemetry,
      DataReeler.Repo,
      {DNSCluster, query: Application.get_env(:data_reeler, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DataReeler.PubSub},
      # Start a worker by calling: DataReeler.Worker.start_link(arg)
      # {DataReeler.Worker, arg},
      # Start to serve requests, typically the last entry
      DataReelerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataReeler.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DataReelerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
