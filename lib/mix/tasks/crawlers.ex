defmodule Mix.Tasks.DataReeler.Crawlers do
  use Mix.Task
  
  @shortdoc """
  Start the crawlers!
  """
  def run(_args) do
    Application.put_env(:data_reeler, :called_in_task, true, persistent: true)
    
    Mix.Tasks.Run.run(run_args())
  end
  
  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end
  
  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end
end