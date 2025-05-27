defmodule Promptly.Repo do
  use Ecto.Repo,
    otp_app: :promptly,
    adapter: Ecto.Adapters.Postgres
end
