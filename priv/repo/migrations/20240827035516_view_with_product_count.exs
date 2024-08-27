defmodule DataReeler.Repo.Migrations.ViewWithProductCount do
  use Ecto.Migration

  def up do
    execute """
      CREATE OR REPLACE VIEW potentially_missing_translations AS
        SELECT
          DISTINCT products.categories AS original_categories,
          category_translations.translated_categories AS translated_categories,
          category_translations.id AS category_translation_id,
          COUNT(products.id) OVER (PARTITION BY products.categories) AS product_count
        FROM
          products
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

    execute """
      CREATE VIEW potentially_missing_translations AS
        SELECT
          DISTINCT products.categories AS original_categories,
          category_translations.translated_categories AS translated_categories,
          category_translations.id AS category_translation_id
        FROM
          products
        LEFT OUTER JOIN
          category_translations
        ON
          products.categories = category_translations.original_categories;
    """
  end
end
