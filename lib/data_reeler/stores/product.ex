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
    field :translated_categories, {:array, :string}, virtual: true
    field :tags, {:array, :string}

    belongs_to :brand, DataReeler.Stores.Brand

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:sku, :price, :images, :categories, :provider, :url, :title, :description, :brand_id, :tags])
    |> validate_required([:sku, :price, :images, :categories, :provider, :url, :title, :description, :brand_id])
    |> unique_constraint([:sku, :provider], name: :unique_sku_on_provider)
  end

  def encode_xml(%__MODULE__{} = product) do
    "<product>" <>
      "<pid>" <>
        encode_xml_field(product.sku) <>
      "</pid>" <>
      "<name>" <>
        encode_xml_field(product.title) <>
      "</name>" <>
      "<description>" <>
        encode_xml_field(Enum.join(product.description, "\n")) <>
      "</description>" <>
      "<url>" <>
        encode_xml_field(product.url) <>
      "</url>" <>
      "<categories>" <>
        encode_xml_field(Enum.join(capitalize_each_element(product.translated_categories), ", ")) <>
      "</categories>" <>
      "<tags>" <>
        encode_xml_field(Enum.join(product.tags, ", ")) <>
      "</tags>" <>
      "<brand>" <>
        encode_xml_field(product.brand.name) <>
      "</brand>" <>
      "<price>" <>
        encode_xml_field(Enum.join(Enum.map(product.price, fn price -> :erlang.float_to_binary(price, decimals: 2) end), ", ")) <>
      "</price>" <>
      "<image>" <>
        encode_xml_field(product.images |> List.first())<>
      "</image>" <>
    "</product>"
  end

  defp capitalize_each_element(elements) when is_list(elements) do
    elements
    |> Enum.map(&capitalize_each_element/1)
  end

  defp capitalize_each_element(element) when is_binary(element) do
    element
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
  
  defp capitalize_each_element(nil), do: []

  defp capitalize_each_element(any), do: any

  defp encode_xml_field(field) do
    XMLRPC.Encode.escape_attr("#{field}")
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
