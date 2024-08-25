defmodule DataReeler.Repo.Migrations.AddIndexOnProductCategories do
  use Ecto.Migration

  def up do
    create index(:products, [:categories])
  end

  def down do
    drop index(:products, [:categories])
  end
end
