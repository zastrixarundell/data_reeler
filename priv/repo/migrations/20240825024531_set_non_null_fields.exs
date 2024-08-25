defmodule DataReeler.Repo.Migrations.SetNonNullFields do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify :categories, {:array, :string}, null: false
      modify :provider, :string, null: false
      modify :url, :string, null: false
      modify :title, :string, null: false
      modify :sku, :string, null: false
      modify :price, {:array, :float}, null: false
      modify :images, {:array, :string}, null: false
      modify :description, {:array, :string}, null: false
    end
    
    alter table(:brands) do
      modify :name, :string, null: false
    end
  end
end
