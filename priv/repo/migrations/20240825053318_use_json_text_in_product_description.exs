defmodule DataReeler.Repo.Migrations.UseJsonTextInProductDescription do
  use Ecto.Migration

  def up do
    alter table(:products) do
      modify :description, {:array, :text}, null: false
    end
  end
  
  def down do
    alter table(:products) do
      modify :description, {:array, :string}, null: false
    end
  end
end
