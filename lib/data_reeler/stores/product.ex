defmodule DataReeler.Stores.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :description, {:array, :string}
    field :title, :string
    field :url, :string
    field :provider, :string
    field :sku, :string
    field :price, {:array, :float}
    field :images, {:array, :string}
    field :categories, {:array, :string}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:sku, :price, :images, :categories, :provider, :url, :title, :description])
    |> validate_required([:sku, :price, :images, :categories, :provider, :url, :title, :description])
    |> unique_constraint([:sku, :provider], name: :unique_sku_on_provider)
  end
end
