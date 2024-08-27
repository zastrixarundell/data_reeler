defmodule DataReeler.Repo.Migrations.AddAccessedAtToProducts do
  use Ecto.Migration

  def up do
    alter table(:products) do
      add :accessed_at, :timestamp, default: fragment("NOW()"), null: false
    end
    
    execute "UPDATE products SET accessed_at = updated_at"
  end
  
  def down do
    alter table(:products) do
      remove :accessed_at
    end
  end
end
