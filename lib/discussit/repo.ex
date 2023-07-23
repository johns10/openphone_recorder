defmodule Discussit.Repo do
  use Ecto.Repo,
    otp_app: :discussit,
    adapter: Ecto.Adapters.Postgres
end
