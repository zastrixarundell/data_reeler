defmodule DataReeler.Servers.Topfish do
  use GenServer
  
  alias DataReeler.Crawlers.Topfish
  
  require Logger
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: :topfish_server)
  end
  
  @doc false
  @impl true
  def init(_) do
    Crawly.Engine.start_spider(Topfish)
    schedule_crawly()
    {:ok, []}
  end
  
  def schedule_crawly do
    hours = Application.get_env(:data_reeler, :server_backoff)
    Process.send_after(self(), :schedule, hours * 60 * 60 * 1000)
  end
  
  @impl true
  def handle_info(:schedule, state) do
    
    Logger.debug("Checking if topfish is still running...")
    
    case Crawly.Engine.get_crawl_id(Topfish) do
      {:ok, _uuid} ->
        Logger.debug("Topfish is still running.")
        
      {:error, :spider_not_running} ->
        Crawly.Engine.start_spider(Topfish)  
        Logger.debug("Restarting topfish.")
    end
    
    schedule_crawly()
    
    {:noreply, state}
  end
  
  @doc false
  @impl true
  def terminate(_, _) do
    Crawly.Engine.stop_spider(Topfish)
  end
end