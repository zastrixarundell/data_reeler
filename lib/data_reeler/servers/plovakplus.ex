defmodule DataReeler.Servers.Plovakplus do
  use GenServer
  
  alias DataReeler.Crawlers.Plovakplus
  
  require Logger
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, initial_state(), name: :plovakplus_server)
  end
  
  def schedule_crawly do
    hours = Application.get_env(:data_reeler, :server_backoff)
    Process.send_after(self(), :schedule, hours * 60 * 60 * 1000)
  end
  
  def notify_broken(path, page) do
    GenServer.cast(:plovakplus_server, {:notify_broken, path, page})
  end
  
  def should_try_page?(path, page) do
    GenServer.call(:plovakplus_server, {:should_try_page, path, page})
  end
  
  # Server implementation
  
  defp initial_state() do
    %{
      broken: %{}
    }
  end
  
  @doc false
  @impl true
  def init(state) do
    Crawly.Engine.start_spider(Plovakplus)
    schedule_crawly()
    {:ok, state}
  end
  
  @doc false
  @impl true
  def handle_call({:should_try_page, path, page}, _, state) when page < 1 do
    Logger.debug("Plovakplus has invalid number: #{path} :: #{page}")
    {:reply, false, state}
  end
  
  @doc false
  @impl true
  def handle_call({:should_try_page, path, page}, _, %{broken: broken} = state) do
    reply =
      broken
      |> Map.get(path, Infinity)
      |> Kernel.>(page)
      
    Logger.debug("Plovakplus is safe to try: #{path} :: #{page} : #{reply}")
    
    {:reply, reply, state}
  end
  
  @doc false
  @impl true
  def handle_cast({:notify_broken, path, page}, %{broken: broken} = state) do
    Logger.debug("Notifying of broken URL on Plovakplus: #{path} :: #{page}")
    {:noreply, add_or_update_minimum_broken(state, broken, path, page)}
    |> IO.inspect()
  end
  
  @doc false
  defp add_or_update_minimum_broken(state, broken, path, page) do
    if Map.has_key?(broken, path) do
      Map.replace_lazy(broken, path, &min(&1, page))
    else
      Map.put(broken, path, page)
    end
    |> then(&Map.put(state, :broken, &1))
  end
  
  @impl true
  def handle_info(:schedule, state) do
    
    Logger.debug("Checking if plovakplus is still running...")
    
    started = 
      case Crawly.Engine.get_crawl_id(Plovakplus) do
        {:ok, _uuid} ->
          Logger.debug("Povakplus is still running.")
          false
          
        {:error, :spider_not_running} ->
          Crawly.Engine.start_spider(Plovakplus)  
          Logger.debug("Restarting plovakplus.")
          true
      end
    
    schedule_crawly()
    
    {:noreply, (if started, do: initial_state(), else: state)}
  end
  
  @doc false
  @impl true
  def terminate(_, _) do
    Crawly.Engine.stop_spider(Plovakplus)
  end
end