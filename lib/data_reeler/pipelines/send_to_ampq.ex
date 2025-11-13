defmodule DataReeler.Pipelines.SendToAmpq do
  @moduledoc """
  Pipeline to send crawled items to AMQP broker so that broadway will handle it later.
  """

  @behaviour Crawly.Pipeline

  require Logger

  alias DataReeler.Stores.Product

  @impl Crawly.Pipeline
  def run(item, state) do
    as_product =
      %Product{brand_id: 1}
        |> Product.set_accessed_at()
        |> Product.changeset(item)

    if as_product.valid? do
      item = Map.put(item, :accessed_at, NaiveDateTime.utc_now(:second))
      DataReeler.AmpqConnection.send_message("crawled_results", item)
    end

    {item, state}
  end
end
