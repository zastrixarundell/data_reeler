defmodule DataReeler.Repo.Migrations.CreateCrawlerAccesses do
  use Ecto.Migration

  def change do
    create table(:crawler_accesses) do
      add :crawler_name, :string, null: false
      add :access_count, :integer, default: 0, null: false
      
      timestamps(type: :utc_datetime)
    end
    
    create unique_index :crawler_accesses, [:crawler_name, :inserted_at]
  end
end
