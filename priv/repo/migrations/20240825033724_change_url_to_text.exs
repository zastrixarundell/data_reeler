defmodule DataReeler.Repo.Migrations.ChangeUrlToText do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify :url, :text, null: false
    end
  end
end
