defmodule DataReeler.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :sku, :string
      add :price, {:array, :float}
      add :images, {:array, :string}
      add :categories, {:array, :string}
      add :provider, :string
      add :url, :string
      add :title, :string
      add :description, {:array, :text}
      
      unique_index(:products, [:sku, :provider], name: :unique_sku_on_provider)

      timestamps(type: :utc_datetime)
    end
  end
end
