defmodule DataReeler.Repo.Migrations.CreateCategoryTranslations do
  use Ecto.Migration

  def change do
    create table(:category_translations) do
      add :original_categories, {:array, :string}
      add :translated_categories, {:array, :string}
      
      index(:category_translations, [:original_categories])

      timestamps(type: :utc_datetime)
    end
  end
end
