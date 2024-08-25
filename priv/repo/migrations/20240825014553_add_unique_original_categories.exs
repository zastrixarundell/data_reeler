defmodule DataReeler.Repo.Migrations.AddUniqueOriginalCategories do
  use Ecto.Migration

  def change do
    drop_if_exists index(:category_translations, [:original_categories])
    
    create unique_index(:category_translations, [:original_categories])
  end
end
