defmodule DataReelerWeb.StoreController do
  use DataReelerWeb, :controller

  alias DataReeler.Stores.Product

  def show(conn, %{"store" => store_name}) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_chunked(200)
    |> stream_data(store_name)
  end

  defp stream_data(conn, store_name) do
    chunk(conn, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><products>")

    DataReeler.Repo.transaction(fn ->
      DataReeler.Stores.product_stream(store_name)
      |> Stream.map(fn product -> Product.encode_xml(product) end)
      |> Stream.each(fn xml -> chunk(conn, xml) end)
      |> Stream.run()
    end)

    chunk(conn, "</products>")

    conn
  end
end
