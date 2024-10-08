defmodule DataReeler.Crawlers.Plovakplus do
  use DataReeler.Crawler

  alias DataReeler.Servers.Plovakplus, as: Server

  import DataReeler.Utils.CrawlerHelpers

  @impl Crawly.Spider
  def base_url(), do: "https://www.plovakplus.rs/prodavnica/"

  @impl Crawly.Spider
  def init() do
    urls =
      [
        "https://www.plovakplus.rs/ribolovacka-oprema/stapovi-za-pecanje/",
        "https://www.plovakplus.rs/ribolovacka-oprema/feeder-oprema/",
        "https://www.plovakplus.rs/ribolovacka-oprema/najloni-za-pecanje/",
        "https://www.plovakplus.rs/ribolovacka-oprema/torbe-futrole-rancevi/",
        "https://www.plovakplus.rs/ribolovacka-oprema/hemija-primama-boile-peleti/",
        "https://www.plovakplus.rs/ribolovacka-oprema/plasticne-kutije-kofe-i-sita/",
        "https://www.plovakplus.rs/ribolovacka-oprema/masinice-za-pecanje/",
        "https://www.plovakplus.rs/ribolovacka-oprema/saranska-oprema/",
        "https://www.plovakplus.rs/ribolovacka-oprema/varalice/",
        "https://www.plovakplus.rs/ribolovacka-oprema/cuvarke-za-ribolov/",
        "https://www.plovakplus.rs/ribolovacka-oprema/kamp-oprema/",
        "https://www.plovakplus.rs/ribolovacka-oprema/hranilice-olovne-glave-olova/",
        "https://www.plovakplus.rs/ribolovacka-oprema/nautika/",
        "https://www.plovakplus.rs/ribolovacka-oprema/rod-pod-signalizatori-i-swingeri/",
        "https://www.plovakplus.rs/ribolovacka-oprema/udice/",
        "https://www.plovakplus.rs/ribolovacka-oprema/meredovi/",
        "https://www.plovakplus.rs/ribolovacka-oprema/garderoba/",
        "https://www.plovakplus.rs/ribolovacka-oprema/sitan-pribor/"
      ]
      |> Enum.reduce([], fn url, acc -> acc ++ generate_initial_list(url) end)

    [
      start_urls: urls ++ DataReeler.Stores.random_store_seed_urls("plovakplus")
    ]
  end

  defp generate_initial_list(start_url) do
    Logger.debug("Starting URL checks for #{inspect(start_url)}")

    with {:ok, %{body: body, status_code: 200}} <- HTTPoison.get(start_url),
         {:ok, document} <- Floki.parse_document(body) do
      output =
        document
        |> Floki.find(".product-category > a")
        |> Floki.attribute("href")

      Logger.debug("Generated URLs: #{inspect(output)}")

      output
    else
      _ ->
        Logger.warning("Failed to generate URLs for: #{inspect(start_url)}")
        []
    end
  end

  @impl Crawly.Spider
  def parse_item(%HTTPoison.Response{status_code: 404, request_url: url}) do
    with %URI{path: path} <- URI.parse(url),
         true <- Regex.match?(~r/page\/\d+\/?$/, path) do
      page_value =
        Regex.run(~r/(\d+)\/?$/, path)
        |> List.last()
        |> String.to_integer()

      non_numbered_path = String.replace(path, ~r/page\/\d+\/?$/, "")

      Server.notify_broken(non_numbered_path, page_value)

      %Crawly.ParsedItem{items: [], requests: []}
    else
      _ ->
        %Crawly.ParsedItem{items: [], requests: []}
    end
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
          acquire_landing_page_data(response, document)
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
    %{
      title:
        document
        |> Floki.find("#primary")
        |> Floki.find("h2.product_title.entry-title.show-product-nav")
        |> Floki.text()
        |> String.trim(),

      categories:
        document
        |> Floki.find("ul.breadcrumb > li a[itemprop=item]")
        |> Enum.drop(2)
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&blank?/1)
        |> Enum.reject(&reject_uncategorized?/1),

      barcode:
        document
        |> Floki.find("#primary")
        |> Floki.find("span.ean")
        |> floki_regex_extraction(~r/(\d{8,128})/i),

      description:
        document
        |> Floki.find("#primary")
        |> Floki.find(
          "div.description.woocommerce-product-details__short-description > p," <> " " <>
          "div.description.woocommerce-product-details__short-description > div")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.split(&1,"\n"))
        |> List.flatten()
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&blank?/1),

      price:
        document
        |> Floki.find("#primary")
        |> Floki.find("p.price")
        |> Floki.find("span.woocommerce-Price-amount.amount")
        |> Floki.find("bdi")
        |> Enum.map(&Floki.text(&1, deep: false))
        |> Enum.map(&String.trim/1)
        |> Enum.reverse()
        |> Enum.map(&normalize_price/1),

      images:
        document
        |> Floki.find("#primary")
        |> Floki.find(".product-images")
        |> Floki.find("img")
        |> Floki.attribute("src"),

      url:
        response.request_url,

      provider:
        "plovakplus",

      brand_name:
        document
        |> Floki.find("#tab-pwb_tab-content")
        |> Floki.find("h3")
        |> List.first()
        |> Floki.text()
        |> String.trim()
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

  defp reject_uncategorized?({_, _, [text]}) when is_bitstring(text) do
    String.equivalent?(String.downcase(text), "uncategorized")
  end

  defp reject_uncategorized?(_), do: false

  # Scrape the landing page for potential request URLs. This doesn't add new
  # products as they don't have all of the information here, although it's
  # good to get stuff en-masse.
  @spec acquire_landing_page_data(response :: HTTPoison.Response.t(), document :: Floki.html_tree())
    :: {items :: [], requests :: Enumerable.t(Crawly.Request.t())}
  defp acquire_landing_page_data(response, document) do
    landing_page_products =
      document
      |> Floki.find("a.product-loop-title")
      |> Floki.attribute("href")

    landing_page_categories =
      document
      |> Floki.find("span.category-list")
      |> Floki.find("a[rel=tag]")
      |> Floki.attribute("href")

    req_with_page =
      response.request_url
      |> URI.parse()
      |> increment_request_url()

    requests =
      landing_page_products
      |> Enum.concat(landing_page_categories)
      |> Enum.concat(req_with_page)
      |> Enum.uniq()
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    {[], requests}
  end

  defp increment_request_url(%URI{path: path} = uri) do
    non_numbered_path = String.replace(path, ~r/page\/\d+\/?$/, "")
    new_number = fetch_page_number(path) + 1

    if Server.should_try_page?(non_numbered_path, new_number) do
      %URI{uri | path: non_numbered_path}
      |> URI.append_path("/page")
      |> URI.append_path("/#{new_number}")
      |> add_trailing_slash()
      |> URI.to_string()
      |> List.wrap()
    else
      []
    end
  end

  defp add_trailing_slash(%URI{path: path} = uri) do
    %URI{uri | path: "#{path}/"}
  end

  defp fetch_page_number(path) do
    if Regex.match?(~r/page\/\d+\/?$/, path) do
      Regex.run(~r/(\d+)\/?$/, path)
      |> List.last()
      |> String.to_integer()
    else
      1
    end
  end

  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()
end
