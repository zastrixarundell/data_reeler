defmodule DataReeler.Repo.Migrations.RenameProductsSkuToBarcode do
  use Ecto.Migration

  def change do
    rename table(:products), :sku, to: :barcode
  end
end
