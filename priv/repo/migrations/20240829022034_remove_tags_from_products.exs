defmodule DataReeler.Repo.Migrations.RemoveTagsFromProducts do
  use Ecto.Migration

  def up do
    alter table(:products) do
      remove :tags
    end
  end
  
  def down do
    alter table(:products) do
      add :tags, {:array, :string}
    end
  end
end
