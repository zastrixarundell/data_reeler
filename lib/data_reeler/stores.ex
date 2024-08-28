defmodule DataReeler.Stores do
  @moduledoc """
  The Stores context.
  """

  import Ecto.Query, warn: false
  require Logger
  
  alias DataReeler.Repo
  alias DataReeler.Stores.{Product, CategoryTranslation, Brand, CrawlerAccess}

  def upsert_product_by_sku_and_provider(values) do
    product =
      Repo.one(
        from p in Product,
        where: p.sku == ^values.sku,
        where: p.provider == ^values.provider
      )

    {brand_name, values} = Map.pop(values, :brand_name)

    with {:ok, brand} <- find_or_create_brand_by_name(brand_name) do
      values = Map.put(values, :brand_id, brand.id)

      case product do
        nil ->
          %{product: create_product(values), accessed_at_old: nil}

        existing ->
          Logger.debug("Product with values: #{inspect(%{sku: values.sku, provider: values.provider, title: values.title})} already exists!", ansi_color: :yellow)
          %{product: update_product(existing, values), accessed_at_old: existing.accessed_at}
      end
    else
      error_message ->
        error_message
    end
  end

  @doc """
  Get random product URLs from the database for the given provider.
  """
  @spec random_store_seed_urls(provider :: binary(), limit :: integer()) :: [binary()]
  def random_store_seed_urls(provider, limit \\ 100) do
    Repo.all(
      from p in Product,
      where: p.provider == ^provider,
      order_by: fragment("RANDOM()"),
      limit: ^limit,
      select: p.url
    )
  end

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Return the stream of all products for stores
  """
  def product_stream(store_name \\ nil)

  def product_stream(store_name) when not is_nil(store_name) do
    query =
      from p in Product,
        where: p.provider == ^store_name,
        join: brand in assoc(p, :brand),
        join: translation in CategoryTranslation,
        on: fragment("? = ?", p.categories, translation.original_categories),
        select: %Product{p | brand: brand, brand_id: brand.id, translated_categories: translation.translated_categories}

    Repo.stream(query)
  end

  def product_stream(nil) do
    query =
      from p in Product,
        join: brand in assoc(p, :brand),
        join: translation in CategoryTranslation,
        on: fragment("? = ?", p.categories, translation.original_categories),
        select: %Product{p | brand: brand, brand_id: brand.id, translated_categories: translation.translated_categories}

    Repo.stream(query)
  end

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    attrs =
      attrs
      |> Map.put(:accessed_at, DateTime.utc_now())

    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  def find_or_create_brand_by_name(name) do
    case get_brand_by_name(name) do
      nil ->
        create_brand(%{name: name})

      existing ->
        Logger.debug("Brand with name: #{existing.name} found!")
        {:ok, existing}
    end
  end

  @doc """
  Gets a single brand.

  Raises `Ecto.NoResultsError` if the Brand does not exist.

  ## Examples

      iex> get_brand_by_name("steg")
      {:ok, %Brand{name: "steg"}}

      iex> get_brand_by_name("steg123")
      {:error, nil}

  """
  def get_brand_by_name(name) do
    Repo.one(
      from b in Brand,
        where: fragment("LOWER(?) LIKE LOWER(?)", b.name, ^name)
    )
  end

  @doc """
  Creates a brand.

  ## Examples

      iex> create_brand(%{field: value})
      {:ok, %Brand{}}

      iex> create_brand(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_brand(attrs \\ %{}) do
    Logger.debug("Creating brand with name: #{attrs.name}.")

    %Brand{}
    |> Brand.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking brand changes.

  ## Examples

      iex> change_brand(brand)
      %Ecto.Changeset{data: %Brand{}}

  """
  def change_brand(%Brand{} = brand, attrs \\ %{}) do
    Brand.changeset(brand, attrs)
  end
  
  def log_crawler_access(nil, cralwer_name) do
    log_crawler_access(cralwer_name)
  end
  
  def log_crawler_access(aao, crawler_name) do
    aao_date = aao |> NaiveDateTime.to_date()
    date_now = Date.utc_today()
    
    if (aao_date == date_now) do
      Logger.debug("Product date already logged.")
      :ok
    else
      log_crawler_access(crawler_name)
    end
    
  end
  
  defp log_crawler_access(crawler_name) do
    potential_log =
      Repo.one(
        from ca in CrawlerAccess,
          where: ca.crawler_name == ^crawler_name,
          where: fragment("CAST(inserted_at AS DATE) = CAST(NOW() AS DATE)"),
          select: ca.id
      )
      
    case potential_log do
      nil ->
        Logger.debug("No #{crawler_name} log found for today... Creating one")
        
        insert_resp =
          %CrawlerAccess{}
          |> CrawlerAccess.changeset(%{crawler_name: crawler_name})
          |> Repo.insert()
          
        case insert_resp do
          {:ok, _} ->
            :ok
            
          {:error, reason} ->
            {:error, :failed_log, reason}
        end

      log_id ->
        Logger.debug("#{crawler_name} log found for today, incrementing")
        
        query =
          from ca in CrawlerAccess,
            where: ca.id == ^log_id
        
        Repo.update_all(
          query,
          inc: [access_count: 1]
        )
        
        :ok
    end
    
    :ok
  end
end
