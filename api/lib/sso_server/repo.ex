defmodule SsoServer.Repo do
  use Ecto.Repo,
    otp_app: :sso_server,
    adapter: Ecto.Adapters.Postgres
end
