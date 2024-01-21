defmodule DataReeler.Servers.Plovakplus do
  use GenServer
  
  alias DataReeler.Crawlers.Plovakplus
  
  require Logger
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end
  
  @doc false
  @impl true
  def init(_) do
    Crawly.Engine.start_spider(Plovakplus)
    schedule_crawly()
    {:ok, []}
  end
  
  def schedule_crawly do
    Process.send_after(self(), :schedule, 24 * 60 * 60 * 1000)
  end
  
  @impl true
  def handle_info(:schedule, state) do
    
    Logger.debug("Checking if plovakplus is still running...")
    
    case Crawly.Engine.get_crawl_id(Plovakplus) do
      {:ok, _uuid} ->
        Logger.debug("Povakplus is still running.")
        
      {:error, :spider_not_running} ->
        Crawly.Engine.start_spider(Plovakplus)  
        Logger.debug("Restarting plovakplus.")
    end
    
    schedule_crawly()
    
    {:noreply, state}
  end
  
  @doc false
  @impl true
  def terminate(_, _) do
    Crawly.Engine.stop_spider(Plovakplus)
  end
end