defmodule DataReeler.Pipelines.ProductDatabase do
  @behaviour Crawly.Pipeline
  
  require Logger
  
  @impl Crawly.Pipeline
  def run(item, state) do
    
    Logger.debug("Calling custom pipeline with structure: #{inspect(item)}")
    
    {item, state}
  end
end