defmodule DataReeler.Crawlers.Plovakplus do
  use Crawly.Spider
  
  require Logger
  
  @impl Crawly.Spider
  def base_url(), do: "https://www.plovakplus.rs/prodavnica/"
  
  @impl Crawly.Spider
  def init() do
    [
      start_urls: ["https://www.plovakplus.rs/prodavnica/"]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)
    
    {items, requests} =
      case page_type(document) do
        :product ->
          Logger.debug("Entered product page for `plovakplus` on URL: #{inspect(response.request_url)}")
          acquire_product_page_data(response, document)
        :landing ->
          Logger.debug("Entered landing page for `plovakplus` on URL: #{inspect(response.request_url)}")
          acquire_landing_page_data(document)
      end
    
    %Crawly.ParsedItem{items: items, requests: requests |> Enum.to_list()}
  end
  
  # Manually added
  
  @spec page_type(document :: Floki.html_tree()) :: :product | :landing
  defp page_type(document) do
    product_list =
      document
      |> Floki.find("div#primary")
      |> Floki.find("main#content")
      |> Floki.find("div.archive-products")
      
    if Enum.empty?(product_list) do
      :product
    else
      :landing
    end
  end
  
  # This scrapes the product pages specifically. Also give any connected
  # product as a request.
  @spec acquire_product_page_data(response :: HTTPoison.Response.t(), document :: Floki.html_tree())
    :: {items :: [map()], requests :: Enumerable.t(Crawly.Request.t())}
  defp acquire_product_page_data(response, document) do
    {[item!(document, response)], item_urls!(document)}
  end
  
  defp item!(document, response) do
    posted_in =
      document
      |> Floki.find("#primary")
      |> Floki.find("span.posted_in")
      
    %{
      title:
        document
        |> Floki.find("#primary")
        |> Floki.find("h2.product_title.entry-title.show-product-nav")
        |> Floki.text()
        |> String.trim(),
        
      categories:
        posted_in
        |> Floki.find("a")
        |> Enum.reject(&reject_uncategorized?/1)
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.downcase/1),
        
      sku:
        document
        |> Floki.find("#primary")
        |> Floki.find("span.sku")
        |> Floki.text()
        |> String.trim(),

      description:
        document
        |> Floki.find("#primary")
        |> Floki.find(
          "div.description.woocommerce-product-details__short-description > p," <> " " <>
          "div.description.woocommerce-product-details__short-description > div")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.split(&1,"\n"))
        |> List.flatten()
        |> Enum.reject(&(&1==""))
        |> Enum.map(&String.trim/1),
        
      price:
        document
        |> Floki.find("#primary")
        |> Floki.find("p.price")
        |> Floki.find("span.woocommerce-Price-amount.amount")
        |> Floki.find("bdi")
        |> Enum.map(&Floki.text(&1, deep: false))
        |> Enum.map(&String.trim/1)
        |> Enum.map(&normalize_price/1),
        
      images: 
        document
        |> Floki.find("#primary")
        |> Floki.find(".product-images")
        |> Floki.find("img")
        |> Floki.attribute("src"),
        
      url: 
        response.request.url,
    
      provider:
        "plovakplus"
    }
  end
  
  defp item_urls!(document) do
    posted_in =
      document
      |> Floki.find("#primary")
      |> Floki.find("span.posted_in")
      
    related_products =
      document
        |> Floki.find(".related.products ul li")  
      
    related_categories =
      related_products
      |> Floki.find("span.category-list")
      |> Floki.find("a[rel=tag]")
      |> Enum.reject(&reject_uncategorized?/1)
      |> Floki.attribute("href")
      
    related_product_urls =
      related_products
      |> Floki.find("a.product-loop-title")
      |> Floki.attribute("href")
      
    category_url =
      posted_in
      |> Floki.find("a")
      |> Floki.attribute("href")
      
    related_categories
    |> Enum.concat(related_product_urls)
    |> Enum.concat(category_url)
    |> Enum.uniq()
    |> Enum.map(&build_absolute_url/1)
    |> Enum.map(&Crawly.Utils.request_from_url/1)
  end
  
  defp normalize_price(price) when is_bitstring(price) do
    price
    |> String.replace(~r/[,.]/, "")
    |> String.to_integer()
    |> Kernel./(100.00)
  end
  
  defp normalize_price(_) do
    -1
  end
  
  defp reject_uncategorized?({_, _, [text]}) when is_bitstring(text) do
    String.equivalent?(String.downcase(text), "uncategorized")
  end
  
  defp reject_uncategorized?(_), do: false
  
  # Scrape the landing page for potential request URLs. This doesn't add new
  # products as they don't have all of the information here, although it's
  # good to get stuff en-masse.
  @spec acquire_landing_page_data(document :: Floki.html_tree())
    :: {items :: [], requests :: Enumerable.t(Crawly.Request.t())}
  defp acquire_landing_page_data(document) do
    landing_page_products =
      document
      |> Floki.find("a.product-loop-title")
      |> Floki.attribute("href")
      
    landing_page_categories =
      document
      |> Floki.find("span.category-list")
      |> Floki.find("a[rel=tag]")
      |> Floki.attribute("href")

    requests =
      landing_page_products
      |> Enum.concat(landing_page_categories)
      |> Enum.uniq()
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)
      
    {[], requests}
  end
  
  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end