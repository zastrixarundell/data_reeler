defmodule DataReeler.Stores do
  @moduledoc """
  The Stores context.
  """

  import Ecto.Query, warn: false
  require Logger
  alias DataReeler.Repo

  alias DataReeler.Stores.Product
  
  def upsert_product_by_sku_and_provider(values) do
    product =
      Repo.one(
        from p in Product,
        where: p.sku == ^values.sku,
        where: p.provider == ^values.provider
      )
    
    case product do
      nil ->
        create_product(values)
        
      existing ->
        Logger.debug("Product with values: #{inspect(%{sku: values.sku, provider: values.provider, title: values.title})} already exists!", ansi_color: :yellow)
        update_product(existing, values)
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
  
  def product_stream(store_name) when is_binary(store_name) do
    query =
      from p in Product,
        where: p.provider == ^store_name
        
    Repo.stream(query)
  end
  
  def product_stream(nil) do
    Repo.stream(Product)
  end
  

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

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
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
