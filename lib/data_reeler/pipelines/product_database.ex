defmodule DataReeler.Pipelines.ProductDatabase do
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state) do
    try do
      case DataReeler.Stores.upsert_product_by_sku_and_provider(item) do
        {:ok, _} ->
          Logger.info("Saved product: #{inspect(item)}")
        {:error, error} ->
          Logger.warning("Falied to insert production #{inspect(item)} with error: #{inspect(error)}")
      end
    rescue
      e in RuntimeError -> e
        Logger.error("Failed to save #{item}")
        rairse "nope"
    end

    {item, state}
  end
end
