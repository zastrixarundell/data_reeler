defmodule DataReeler.Servers.Formaxstore do
  use GenServer
  
  alias DataReeler.Crawlers.Formaxstore
  
  require Logger
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: :formaxstore_server)
  end
  
  @doc false
  @impl true
  def init(_) do
    Crawly.Engine.start_spider(Formaxstore)
    schedule_crawly()
    {:ok, []}
  end
  
  def schedule_crawly do
    hours = Application.get_env(:data_reeler, :server_backoff)
    Process.send_after(self(), :schedule, hours * 60 * 60 * 1000)
  end
  
  @impl true
  def handle_info(:schedule, state) do
    
    Logger.debug("Checking if formaxstore is still running...")
    
    case Crawly.Engine.get_crawl_id(Formaxstore) do
      {:ok, _uuid} ->
        Logger.debug("Formaxstore is still running.")
        
      {:error, :spider_not_running} ->
        Crawly.Engine.start_spider(Formaxstore)  
        Logger.debug("Restarting formaxstore.")
    end
    
    schedule_crawly()
    
    {:noreply, state}
  end
  
  @doc false
  @impl true
  def terminate(_, _) do
    Crawly.Engine.stop_spider(Formaxstore)
  end
end