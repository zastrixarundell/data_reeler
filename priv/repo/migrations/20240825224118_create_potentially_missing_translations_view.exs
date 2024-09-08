defmodule DataReeler.Repo.Migrations.CreatePotentiallyMissingTranslationsView do
  use Ecto.Migration

  def up do
    execute """
      CREATE VIEW potentially_missing_translations AS
      SELECT
        products.categories AS original_categories,
        category_translations.translated_categories AS translated_categories
      FROM
        (SELECT DISTINCT categories FROM products) AS products
      LEFT OUTER JOIN
        category_translations
      ON
        products.categories = category_translations.original_categories;
    """
  end
  
  def down do
    execute """
      DROP VIEW potentially_missing_translations;
    """
  end
end
