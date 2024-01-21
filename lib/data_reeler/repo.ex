defmodule DataReeler.Repo do
  use Ecto.Repo,
    otp_app: :data_reeler,
    adapter: Ecto.Adapters.Postgres
end
