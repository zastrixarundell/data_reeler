defmodule DataReeler.Repo.Migrations.ChangeSkuToIsbn do
  use Ecto.Migration

  def change do
    rename table(:products), :sku, to: :isbn
  end
end
