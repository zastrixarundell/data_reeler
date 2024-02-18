defmodule DataReeler.StoresTest do
  use DataReeler.DataCase

  alias DataReeler.Stores

  describe "products" do
    alias DataReeler.Stores.Product

    import DataReeler.StoresFixtures

    @invalid_attrs %{description: nil, title: nil, url: nil, provider: nil, sku: nil, price: nil, images: nil, categories: nil}

    test "list_products/0 returns all products" do
      product = product_fixture()
      assert Stores.list_products() == [product]
    end

    test "get_product!/1 returns the product with given id" do
      product = product_fixture()
      assert Stores.get_product!(product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      valid_attrs = %{description: ["option1", "option2"], title: "some title", url: "some url", provider: "some provider", sku: "some sku", price: [], images: ["option1", "option2"], categories: ["option1", "option2"]}

      assert {:ok, %Product{} = product} = Stores.create_product(valid_attrs)
      assert product.description == ["option1", "option2"]
      assert product.title == "some title"
      assert product.url == "some url"
      assert product.provider == "some provider"
      assert product.sku == "some sku"
      assert product.price == []
      assert product.images == ["option1", "option2"]
      assert product.categories == ["option1", "option2"]
    end

    test "create_product/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stores.create_product(@invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      product = product_fixture()
      update_attrs = %{description: ["option1"], title: "some updated title", url: "some updated url", provider: "some updated provider", sku: "some updated sku", price: [], images: ["option1"], categories: ["option1"]}

      assert {:ok, %Product{} = product} = Stores.update_product(product, update_attrs)
      assert product.description == ["option1"]
      assert product.title == "some updated title"
      assert product.url == "some updated url"
      assert product.provider == "some updated provider"
      assert product.sku == "some updated sku"
      assert product.price == []
      assert product.images == ["option1"]
      assert product.categories == ["option1"]
    end

    test "update_product/2 with invalid data returns error changeset" do
      product = product_fixture()
      assert {:error, %Ecto.Changeset{}} = Stores.update_product(product, @invalid_attrs)
      assert product == Stores.get_product!(product.id)
    end

    test "delete_product/1 deletes the product" do
      product = product_fixture()
      assert {:ok, %Product{}} = Stores.delete_product(product)
      assert_raise Ecto.NoResultsError, fn -> Stores.get_product!(product.id) end
    end

    test "change_product/1 returns a product changeset" do
      product = product_fixture()
      assert %Ecto.Changeset{} = Stores.change_product(product)
    end
  end
end
