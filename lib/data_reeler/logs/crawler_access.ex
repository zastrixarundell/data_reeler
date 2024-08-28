defmodule DataReeler.Logs.CrawlerAccess do
  use Ecto.Schema
  import Ecto.Changeset

  schema "crawler_accesses" do
    field :crawler_name, :string
    field :access_count, :integer, default: 1

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(crawler_access, attrs) do
    crawler_access
    |> cast(attrs, [:crawler_name, :access_count])
    |> validate_length(:crawler_name, max: 255)
    |> validate_required([:crawler_name])
    |> unique_constraint([:crawler_name, :inserted_at], name: :crawler_accesses_crawler_name_inserted_at_index)
  end
end
