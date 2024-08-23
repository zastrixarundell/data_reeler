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
    
    children =
      children
      |> conditional_append(
          should_start_crawlers?(),
          [
            DataReeler.Servers.Plovakplus,
            DataReeler.Servers.Formaxstore,
            DataReeler.Servers.Topfish
          ]
        )
      |> conditional_append(should_start_elasticsearch?(), [DataReeler.Elasticsearch.Cluster])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataReeler.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  defp conditional_append(children, true, new_children) do
    children ++ new_children
  end
  
  defp conditional_append(children, false, _),
    do: children
  
  defp should_start_crawlers?() do
    Application.get_env(:data_reeler, :called_in_task) == true or Application.get_env(:data_reeler, :decoupled_crawlers) == "false"
  end
  
  defp should_start_elasticsearch?() do
    System.get_env("ELASTICSEARCH_URL") |> is_nil() |> Kernel.!()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DataReelerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
