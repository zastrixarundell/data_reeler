defmodule DataReeler.Repo.Migrations.ChangeisbnToIsbn do
  use Ecto.Migration

  def change do
    rename table(:products), :isbn, to: :isbn
  end
end
