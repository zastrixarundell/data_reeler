defmodule DataReeler.Crawlers.MozaikCentar do
  use DataReeler.Crawler

  import DataReeler.Utils.CrawlerHelpers

  @impl Crawly.Spider
  def base_url(), do: "https://www.mozaikcentar.com/"

  @impl Crawly.Spider
  def init() do
    urls =
      [
        "https://www.mozaikcentar.com/sr/proizvodi/stapovi",
        "https://www.mozaikcentar.com/sr/proizvodi/masinice",
        "https://www.mozaikcentar.com/sr/proizvodi/feeder-pecanje",
        "https://www.mozaikcentar.com/sr/proizvodi/somovska-oprema",
        "https://www.mozaikcentar.com/sr/proizvodi/varalice",
        "https://www.mozaikcentar.com/sr/proizvodi/najloni",
        "https://www.mozaikcentar.com/sr/proizvodi/udice",
        "https://www.mozaikcentar.com/sr/proizvodi/pribor",
        "https://www.mozaikcentar.com/sr/proizvodi/oprema",
        "https://www.mozaikcentar.com/sr/proizvodi/rezervni-delovi"
      ] ++ DataReeler.Stores.random_store_seed_urls("mozaik_centar")

    [
      start_urls: urls
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
        :landing_page ->
          {[], []}
      end

    %Crawly.ParsedItem{items: items, requests: requests}
  end

  defp page_type(document) do
    product_page = Floki.find(document, "h1.product-name") |> Enum.any?()
    product_list = Floki.find(document, "a.filter-trigger.btn-t1.red") |> Enum.any?()

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
        |> Floki.find("h1.product-name")
        |> Floki.text()
        |> String.trim(),

      description:
        document
        |> Floki.find(".description")
        |> Floki.find("p")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.split(&1,"\n"))
        |> List.flatten()
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&blank?/1),

      barcode:
        document
        |> Floki.find("section.product-description-tabs-section")
        |> Floki.find("p")
        |> floki_regex_extraction(~r/(barkod *(artikla)?|ean):? *?(\d{8,128})/i),

      categories:
        document
        |> Floki.find("section.breadcrumbs a")
        |> IO.inspect()
        |> Enum.drop(1)
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&blank?/1)
        |> capitalize_first_element(),

      tags:
        [],

      url:
        response.request_url,

      provider:
        "mozaik_centar",

      brand_name:
        document
        |> Floki.find(".price-block > p.price > a")
        |> Floki.text()
        |> String.trim(),

      images:
        document
        |> Floki.find("#glasscase")
        |> Floki.find("img")
        |> Floki.attribute("src")
        |> Enum.map(fn path -> build_absolute_url(path) end),

      price: (
        document
        |> Floki.find(".price-block > p.price")
        |> floki_regex_extraction(~r/([\d\.,]+) *RSD *$/i)
        |> normalize_price()
        |> List.wrap()
      )
    }
  end

  defp capitalize_first_element(array) when is_list(array) do
    with elements when elements > 1 <- Enum.count(array) do
      [head | tail] = array

      [String.capitalize(head)] ++ tail
    else
      _ ->
        if Enum.count(array) == 1 do
          array
          |> List.first()
          |> String.capitalize()
          |> List.wrap()
        else
          array
        end
    end
  end

  def item_urls!(document) do
    document
    |> Floki.find(".products-slider .text-block a")
    |> Floki.attribute("href")
    |> Enum.uniq()
    |> Enum.map(&build_absolute_url/1)
    |> Enum.map(&Crawly.Utils.request_from_url/1)
  end

  defp product_list_page(document, response) do
    item_cards =
      document
      |> Floki.find(".product-preview-item .text-block a")
      |> Floki.attribute("href")

    pagination =
      document
      |> Floki.find("ul.pagination-list > li > a")
      |> Floki.attribute("data-ci-pagination-page")
      |> Enum.map(&String.to_integer/1)
      |> safe_max()
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

  defp safe_max([]), do: nil

  defp safe_max(value), do: Enum.max(value)

  defp build_page_numbers(max_page) when is_integer(max_page) do
    1..max_page
    |> Enum.to_list()
  end

  defp build_page_numbers(_), do: []

  defp build_pagination(page, response) do
    response.request_url
    |> URI.parse()
    |> remove_uri_page()
    |> URI.append_path("/#{page}")
    |> URI.to_string()
  end

  defp remove_uri_page(uri = %URI{path: path}) do
    %URI{uri | path: String.replace(path, ~r/\/\d+\/?$/, "")}
  end

  def build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end
