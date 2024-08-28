defmodule DataReeler.Stores do
  @moduledoc """
  The Stores context.
  """

  import Ecto.Query, warn: false
  require Logger

  alias DataReeler.Repo
  alias DataReeler.Stores.{Product, CategoryTranslation, Brand}

  def upsert_product_by_barcode_and_provider(values) do
    type_check =
      %Product{brand_id: 1}
        |> Product.set_accessed_at()
        |> Product.changeset(values)

    if type_check.valid? do
      product =
        Repo.one(
          from p in Product,
          where: p.barcode == ^values.barcode,
          where: p.provider == ^values.provider
        )

      {brand_name, values} = Map.pop(values, :brand_name)

      with {:ok, brand} <- find_or_create_brand_by_name(brand_name) do
        values = Map.put(values, :brand_id, brand.id)

        case product do
          nil ->
            %{product: create_product(values), accessed_at_old: nil}

          existing ->
            Logger.debug("Product with values: #{inspect(%{barcode: values.barcode, provider: values.provider, title: values.title})} already exists!", ansi_color: :yellow)
            %{product: update_product(existing, values), accessed_at_old: existing.accessed_at}
        end
      else
        error_message ->
          error_message
      end
    else
      {:error, type_check}
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
    product
    |> Product.set_accessed_at()
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
end
