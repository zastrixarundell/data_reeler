defmodule DataReeler.ProductConsumer do
  @moduledoc """
  Broadway consumer module to process crawled items from AMQP broker.
  """

  use Broadway

  alias DataReeler.Stores, as: DB
  alias DataReeler.Stores.Product
  # alias DataReeler.Repo

  def start_link(_args) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: "crawled_results",
           on_failure: :reject_and_requeue}
      ],
      processors: [
        default: [concurrency: 10]
      ],
      batchers: [default: [batch_size: 50, batch_timeout: 2000]]
    )
  end

  @impl Broadway
  def handle_message(_, %{data: data} = message, _) do
    parsed_data = Jason.decode!(data)

    product =
      %Product{brand_id: 1}
      |> Product.changeset(parsed_data)

    # Just do a sanity check, it is verified in the pipeline already but there
    # might be a chance where the structure is updated while the item is in the queue.
    if product.valid? do
      Broadway.Message.update_data(message, fn _ -> {product, parsed_data["brand_name"]} end)
    else
      Broadway.Message.failed(message, :invalid_product)
    end
  end

  @impl Broadway
  def handle_batch(_, messages, _, _) do
    # IO.inspect(messages, label: "Batch of messages")
      Enum.map(messages, fn %{data: {changeset, brand_name}} -> {changeset, brand_name} end)
      |> Enum.uniq() # Remove duplicates in the batch, can happen when multiple crawlers send same item
      |> DB.upsert_products()
    messages
  end
end
