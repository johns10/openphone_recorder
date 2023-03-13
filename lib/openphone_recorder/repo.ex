defmodule OpenphoneRecorder.Repo do
  use Ecto.Repo,
    otp_app: :openphone_recorder,
    adapter: Ecto.Adapters.Postgres
end
