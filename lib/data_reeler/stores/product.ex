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
  
  def encode_xml(%__MODULE__{} = product) do
    "<product>" <>
      "<title>" <>
        encode_xml_field(product.title) <>
      "</title>" <>
      "<description>" <>
        encode_xml_field(Enum.join(product.description, ", ")) <>
      "</description>" <>
      "<url>" <> 
        encode_xml_field(product.url) <>
      "</url>" <>
      "<provider>" <> 
        encode_xml_field(product.provider) <>
      "</provider>" <>
      "<sku>" <> 
        encode_xml_field(product.sku) <>
      "</sku>" <>
      "<price>" <>
        encode_xml_field(Enum.join(Enum.map(product.price, &Float.to_string/1), ", ")) <>
      "</price>" <>
      "<images>" <>
        encode_xml_field(Enum.join(product.images, ", ") )<>
      "</images>" <>
      "<categories>" <>
        encode_xml_field(Enum.join(product.categories, ", ")) <>
      "</categories>" <> 
    "</product>"
  end
  
  defp encode_xml_field(field) do
    XMLRPC.Encode.escape_attr(field)
  end
  
  defimpl Elasticsearch.Document, for: DataReeler.Stores.Product do  
    @spec id(%DataReeler.Stores.Product{}) :: integer()
    def id(product), do: product.id
    
    @spec routing(%DataReeler.Stores.Product{}) :: false
    def routing(_), do: false
    
    def encode(product) do
      %{
        title: product.title,
        description: product.description,
        url: product.url,
        provider: product.provider,
        sku: product.sku,
        price: product.price,
        images: product.images,
        categories: product.categories
      }
    end
  end
end
