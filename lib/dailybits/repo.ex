defmodule Dailybits.Repo do
  use Ecto.Repo,
    otp_app: :dailybits,
    adapter: Ecto.Adapters.Postgres
end
