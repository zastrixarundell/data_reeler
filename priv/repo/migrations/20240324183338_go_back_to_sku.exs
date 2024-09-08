defmodule DataReeler.Repo.Migrations.GoBackToSku do
  use Ecto.Migration

  def change do
    rename table(:products), :isbn, to: :sku
  end
end
