defmodule DataReeler.Repo.Migrations.UseJsonTextInProductDescription do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify :description, {:array, :text}, null: false
    end
  end
end
