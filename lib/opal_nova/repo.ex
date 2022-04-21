defmodule OpalNova.Repo do
  use Ecto.Repo,
    otp_app: :opal_nova,
    adapter: Ecto.Adapters.Postgres
end
