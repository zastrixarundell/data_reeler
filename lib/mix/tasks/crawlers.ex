defmodule Mix.Tasks.DataReeler.Crawlers do
  use Mix.Task
  
  require Logger
  
  @shortdoc """
  Start the crawlers!
  """
  def run(args) do 
    parsed_arguments =
      args
      |> OptionParser.parse(strict: [crawler: :keep])
    
    with {:ok, names} <- crawler_names(parsed_arguments),
         {:ok, crawler_modules} <- as_modules(names) do
          
      Application.put_env(:data_reeler, :called_in_task, true, persistent: true)
      
      if length(crawler_modules) > 0 do
        Application.put_env(:data_reeler, :called_task_modules, crawler_modules, persistent: true)
      end
      
      Mix.Tasks.Run.run(run_args())
    else
      {:error, :invalid_crawler_options, opts} ->
        opts
        |> Enum.map(&"* Unkown option or missing crawler name: #{&1}")
        |> Enum.join("\n")
        |> tap(&IO.write(:stderr, "Failed to start command.\n\n#{&1}\n"))
        
        System.halt(1)
      
      {:error, :failed_module_names, names} ->        
        names
        |> Enum.map(&"* Unkown module name DataReeler.Servers.#{Macro.camelize(&1)}")
        |> Enum.join("\n")
        |> tap(&IO.write(:stderr, "Failed to start command.\n\n#{&1}\n"))

        System.halt(2)
    end
  end
  
  defp as_modules(names) do
    module_names =
      names
      |> Enum.map(fn name ->
        try do
          name
          |> Macro.camelize()
          |> then(&String.to_existing_atom("Elixir.DataReeler.Servers.#{&1}"))
        rescue
          ArgumentError ->
            {:error, name}
        end
      end)
    
    error_names =
      module_names
      |> Enum.filter(fn response ->
        case response do
          {:error, _name} ->
            true
            
          _ ->
            false
        end
      end)
      |> Enum.map(fn {:error, name} -> name end)
      
    if length(error_names) == 0 do
      {:ok, module_names}
    else
      {:error, :failed_module_names, error_names}
    end
  end
  
  defp crawler_names({crawler_options, [], []}) do
    {:ok, Enum.map(crawler_options, &elem(&1, 1))}
  end
  
  defp crawler_names({_, _, options}) when length(options) > 0 do
    invalid_names = Enum.map(options, fn opt -> elem(opt, 0) end)
    {:error, :invalid_crawler_options, invalid_names}
  end
  
  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end
  
  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end
end