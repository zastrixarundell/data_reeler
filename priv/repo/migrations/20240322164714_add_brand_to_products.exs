defmodule DataReeler.Repo.Migrations.AddBrandToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :brand_id, references(:brands, on_delete: :delete_all), null: false
    end
  end
end
