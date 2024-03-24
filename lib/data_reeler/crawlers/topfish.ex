defmodule DataReeler.Crawlers.Topfish do
  use DataReeler.Crawler
  
  @impl Crawly.Spider
  def base_url(), do: "https://www.topfish.rs/"

  @impl Crawly.Spider
  def init() do
    values =
      with {:ok, %{body: body, status_code: 200}} <- HTTPoison.get("https://www.topfish.rs/proizvodi"),
           {:ok, document} <- Floki.parse_document(body) do
        document
        |> Floki.find(".taxonomy-term-category-teaser__field-teaser-image-item > a")
        |> Floki.attribute("href")
        |> Enum.map(&build_absolute_url/1)
      else
        _ ->
          []
      end

    [
      start_urls: values
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
          product_list_page(document, response)
        :product_page ->
          product_page(document, response)
      end

    %Crawly.ParsedItem{items: items, requests: requests}
  end

  defp page_type(document) do
    product_page = Floki.find(document, ".button--add-to-cart.button.button--primary") |> Enum.any?()

    cond do
      product_page -> :product_page
      true -> :product_list
    end
  end

  defp product_page(document, response) do
    {[item!(document, response)], []}
  end

  def item!(document, response) do
    %{
      title:
        document
        |> Floki.find(".commerce-product-default-full__title-item")
        |> Floki.text()
        |> String.trim(),

      description:
        document
        |> Floki.find(".commerce-product-default-full__body-item > p")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.split(&1,"\n"))
        |> List.flatten()
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&blank?/1),

      sku:
        document
        |> Floki.find(".commerce-product-variation-default-full__sku-item")
        |> Floki.text(),

      images:
        document
        |> Floki.find(".gallery-top")
        |> Floki.find("img")
        |> Floki.attribute("src")
        |> Enum.map(fn path -> build_absolute_url(path) end),
        
      categories:
        document
        |> Floki.find(".commerce-product-default-full__field-category-item > a")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.split(&1,"\n"))
        |> List.flatten()
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&blank?/1),

      url:
        response.request_url,

      provider:
        "topfish",

      brand_name:
        document
        |> Floki.find(".commerce-product-default-full__manufacturer")
        |> List.first()
        |> Floki.text()
        |> String.trim(),

      price: (
        prices_holder =
          document
          |> Floki.find(".product-information-wrapper")
          |> Floki.find(".product-details-price")

        price_no_discount =
          prices_holder
          |> Floki.find(".commerce-product-variation-default-full__list-price-item")

        price =
          document
          |> Floki.find(".commerce-product-variation-default-full__price-item")

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
    |> then(&Regex.run(~r/\d+/, &1))
    |> List.flatten()
    |> Enum.join()
    |> String.to_integer()
    |> Kernel./(100.00)
  end

  defp product_list_page(document, response) do
    item_cards =
      document
      |> Floki.find("a.teaser-product__container")
      |> Floki.attribute("href")

    pagination =
      document
      |> Floki.find("li.pager__item--last")
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> List.first()
      |> extract_max_page()
      |> build_page_numbers()
      |> Enum.map(&build_pagination(&1, response))

    requests =
      item_cards
      |> Enum.concat(pagination)
      |> Enum.uniq()
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    {[], requests}
  end
  
  defp extract_max_page(nil), do: []
  
  defp extract_max_page(href) do
    href
    |> URI.parse()
    |> Map.get(:query)
    |> URI.decode_query()
    |> Map.get("page", "0")
    |> String.to_integer()
  end

  defp build_page_numbers(max_page) when is_integer(max_page) do
    1..max_page
    |> Enum.to_list()
  end

  defp build_page_numbers(_), do: []

  defp build_pagination(page, response) do
    response.request_url
    |> URI.parse()
    |> remove_uri_page()
    |> URI.append_query("page=#{page}")
    |> URI.to_string()
  end

  defp remove_uri_page(uri = %URI{query: query}) do
    %URI{uri | query: String.replace(query || "", ~r/&?page=\d+/, "")}
  end

  def build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end
