defmodule DataReeler.Pipelines.ProductDatabase do
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state) do
    with %{product: {:ok, _}, accessed_at_old: aao} <- DataReeler.Stores.upsert_product_by_barcode_and_provider(item),
         :ok <- DataReeler.Logs.log_crawler_access(aao, item.provider) do
      Logger.info("Saved product: #{inspect(item.url)}")
    else
      {:error, error} ->
        Logger.warning("Falied to insert product #{inspect(item.url)} with error: #{inspect(error)}")

      {:error, :failed_log, error} ->
        Logger.error("Falied to save log for #{inspect(item.url)} with error: #{inspect(error)}")
    end

    {item, state}
  end
end
