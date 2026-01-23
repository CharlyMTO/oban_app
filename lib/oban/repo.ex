defmodule ObanApp.Repo do
  use Ecto.Repo,
    otp_app: :oban_app,
    adapter: Ecto.Adapters.Postgres
end
