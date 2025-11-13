defmodule DataReeler.Repo.Migrations.AddUniqueIndexOnBarcodeAndProviderForProducts do
  use Ecto.Migration

  def change do
    create unique_index(:products, [:barcode, :provider], name: :unique_barcode_on_provider)
  end
end
