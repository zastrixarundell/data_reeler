defmodule DataReeler.Repo.Migrations.SetTagsRequiredInProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      modify :tags, {:array, :string}, null: false
    end
  end
end
