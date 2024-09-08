defmodule DataReeler.Stores.CategoryTranslation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "category_translations" do
    field :original_categories, {:array, :string}
    field :translated_categories, {:array, :string}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category_translation, attrs) do
    category_translation
    |> cast(attrs, [:original_categories, :translated_categories])
    |> validate_required([:original_categories, :translated_categories])
  end
end
