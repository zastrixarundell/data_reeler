defmodule DataReeler.Crawlers.Formaxstore do
  use Crawly.Spider
  
  require Logger
  
  @impl Crawly.Spider
  def base_url(), do: "https://www.formaxstore.com/"
  
  @impl Crawly.Spider
  def init() do
    values =
      with {:ok, %{body: body, status_code: 200}} <- HTTPoison.get("https://www.formaxstore.com"),
           {:ok, document} <- Floki.parse_document(body) do
        document
        |> Floki.find(".nav-main.list-inline")
        |> Floki.find(".level4")
        |> Floki.find("ul.nav-main-submenu")
        |> Floki.find("li > a")
        |> Floki.attribute("href")
      else
        _ ->
          []
      end

    [
      start_urls: values ++ ["https://www.formaxstore.com"] ++ DataReeler.Stores.random_store_seed_urls("formaxstore")
    ]
  end
  
  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)
    
    actual_page_type = page_type(document)
    
    Logger.debug("Page type for #{inspect(response.request_url)} is #{inspect(actual_page_type)}")
    
    {items, requests} =
      case actual_page_type do
        :product_list ->
          product_list_page(document)
        :product_page ->
          product_page(document, response)
        :landing_page ->
          {[], []}
      end
    
    %Crawly.ParsedItem{items: items, requests: requests}
  end
  
  defp page_type(document) do
    product_page = Floki.find(document, ".product-information-wrapper") |> Enum.any?()
    product_list = Floki.find(document, ".tp-product_list") |> Enum.any?()
    # landing_page = Floki.find(document, ".heading-wrapper.heading-wrapper-bordered") |> Enum.empty?()
    
    cond do
      product_page -> :product_page
      product_list -> :product_list
      true -> :landing_page
    end
  end
  
  defp product_page(document, response) do    
    {[item!(document, response)], item_urls!(document)}
  end
  
  def item!(document, response) do
    %{
      title:
        document
        |> Floki.find(".heading-wrapper")
        |> Floki.find(".title")
        |> Floki.find("h1")
        |> Floki.text()
        |> String.trim(),
        
      description:
        document
        |> Floki.find("#tab_product_description")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.split(&1,"\n"))
        |> List.flatten()
        |> Enum.reject(&(&1==""))
        |> Enum.map(&String.trim/1),
        
      sku:
        document
        |> Floki.find(".product-details-info > .code > span")
        |> Floki.text(),
        
      categories:
        document
        |> Floki.find("table.product-attrbite-table")
        |> Floki.find("tbody")
        |> Floki.find("tr:not(.attr-brend)")
        |> Floki.find("td > a")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.split(&1,"\n"))
        |> List.flatten()
        |> Enum.reject(&(&1==""))
        |> Enum.map(&String.trim/1),
        
      url:
        response.request_url,
        
      provider:
        "formaxstore",
        
      images:
        document
        |> Floki.find(".product-image-wrapper")
        |> Floki.find("img")
        |> Floki.attribute("src")
        |> Enum.map(fn path -> build_absolute_url(path) end),
        
      price: (
        prices_holder =
          document
          |> Floki.find(".product-information-wrapper")
          |> Floki.find(".product-details-price")
        
        price_no_discount =
          prices_holder
          |> Floki.find("span.value.product-price-without-discount-value")
          
        price =
          prices_holder
          |> Floki.find("span.value.product-price-value")
          
        price_no_discount
        |> Enum.concat(price)
        |> Enum.map(&Floki.text(&1, deep: false))
        |> Enum.map(&String.trim/1)
        |> Enum.map(&normalize_price/1)
        |> Enum.uniq()
      )
    }
  end
  
  defp normalize_price(price) when is_bitstring(price) do
    price
    |> String.replace(~r/[,.]/, "")
    |> String.to_integer()
    |> Kernel./(100.00)
  end
  
  def item_urls!(document) do
    similar_products = [
      document
      |> Floki.find(".similar-products-slider")
      |> Floki.find(".item.product-item")
      |> Floki.find(".img-wrapper > a")
      |> Floki.attribute("href")]
      
    document
    |> Floki.find(".product-details-related")
    |> Floki.find("li.item > a")
    |> Floki.attribute("href")
    |> Enum.concat(similar_products)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(&build_absolute_url/1)
    |> Enum.map(&Crawly.Utils.request_from_url/1)
  end
  
  defp product_list_page(document) do
    item_cards =
      document
      |> Floki.find(".item.product-item")
      |> Floki.find(".img-wrapper > a")
      |> Floki.attribute("href")
      
    categories =
      document
      |> Floki.find("#nb_f-kategorije")
      |> Floki.find("li > a")
      |> Floki.attribute("href")
      
    requests =
      item_cards
      |> Enum.concat(categories)
      |> Enum.uniq()
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)
      
    {[], requests}
  end
  
  def build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end