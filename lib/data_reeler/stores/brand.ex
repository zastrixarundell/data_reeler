defmodule DataReeler.Stores.Brand do
  use Ecto.Schema
  import Ecto.Changeset

  schema "brands" do
    field :name, :string
    
    has_many :products, DataReeler.Stores.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(brand, attrs) do
    brand
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
