defmodule DataReelerWeb.ProductController do
  alias DataReeler.Stores.Product
  use DataReelerWeb, :controller
  
  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_chunked(200)
    |> stream_data()
  end
  
  defp stream_data(conn) do
    chunk(conn, "<?xml version=\"1.0\" encoding=\"UTF-8\"?><products>")
    
    DataReeler.Repo.transaction(fn ->
      DataReeler.Stores.product_stream()
      |> Stream.map(fn product -> Product.encode_xml(product) end)
      |> Stream.each(fn xml -> chunk(conn, xml) end)
      |> Stream.run()
    end)
    
    chunk(conn, "</products>")
    
    conn
  end
end