defmodule DataReeler.Pipelines.ProductDatabase do
  @behaviour Crawly.Pipeline

  require Logger

  @impl Crawly.Pipeline
  def run(item, state) do
    case DataReeler.Stores.upsert_product_by_isbn_and_provider(item) do
      {:ok, _} ->
        nil
      {:error, error} ->
        Logger.warning("Falied to insert production #{inspect(item)} with error: #{inspect(error)}")
    end

    {item, state}
  end
end
