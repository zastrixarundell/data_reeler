defmodule Mix.Tasks.DataReeler.Crawlers do
  use Mix.Task
  
  @requirements ["app.start"]
  
  @shortdoc """
  Start the crawlers!
  """
  def run(_args) do
    children = [
      # DataReeler.Servers.Plovakplus,
      # DataReeler.Servers.Formaxstore,
      DataReeler.Servers.Topfish
    ]
    
    opts = [strategy: :one_for_one, name: DataReeler.CrawlerSupervisor]
    Supervisor.start_link(children, opts)
    
    loop()
  end
  
  defp loop do
    Process.sleep(1000)
    
    loop()
  end
end