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

  describe "brands" do
    alias DataReeler.Stores.Brand

    import DataReeler.StoresFixtures

    @invalid_attrs %{name: nil}

    test "list_brands/0 returns all brands" do
      brand = brand_fixture()
      assert Stores.list_brands() == [brand]
    end

    test "get_brand!/1 returns the brand with given id" do
      brand = brand_fixture()
      assert Stores.get_brand!(brand.id) == brand
    end

    test "create_brand/1 with valid data creates a brand" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Brand{} = brand} = Stores.create_brand(valid_attrs)
      assert brand.name == "some name"
    end

    test "create_brand/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stores.create_brand(@invalid_attrs)
    end

    test "update_brand/2 with valid data updates the brand" do
      brand = brand_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Brand{} = brand} = Stores.update_brand(brand, update_attrs)
      assert brand.name == "some updated name"
    end

    test "update_brand/2 with invalid data returns error changeset" do
      brand = brand_fixture()
      assert {:error, %Ecto.Changeset{}} = Stores.update_brand(brand, @invalid_attrs)
      assert brand == Stores.get_brand!(brand.id)
    end

    test "delete_brand/1 deletes the brand" do
      brand = brand_fixture()
      assert {:ok, %Brand{}} = Stores.delete_brand(brand)
      assert_raise Ecto.NoResultsError, fn -> Stores.get_brand!(brand.id) end
    end

    test "change_brand/1 returns a brand changeset" do
      brand = brand_fixture()
      assert %Ecto.Changeset{} = Stores.change_brand(brand)
    end
  end
end
