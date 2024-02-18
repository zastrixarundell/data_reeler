defmodule DataReeler.StoresFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataReeler.Stores` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        categories: ["option1", "option2"],
        description: ["option1", "option2"],
        images: ["option1", "option2"],
        price: [],
        provider: "some provider",
        sku: "some sku",
        title: "some title",
        url: "some url"
      })
      |> DataReeler.Stores.create_product()

    product
  end
end
