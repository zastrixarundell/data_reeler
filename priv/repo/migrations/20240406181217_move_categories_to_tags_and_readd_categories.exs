defmodule DataReeler.Repo.Migrations.MoveCategoriesToTagsAndReaddCategories do
  use Ecto.Migration

  def up do
    alter table(:products) do
      add :tags, {:array, :string}
    end
    
    execute("UPDATE products SET tags = array(select lower(unnest(categories::text[])))")
  end
  
  def down do
    alter table(:products) do
      remove :tags
    end
  end
end
