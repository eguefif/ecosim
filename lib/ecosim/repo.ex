defmodule Ecosim.Repo do
  use Ecto.Repo,
    otp_app: :ecosim,
    adapter: Ecto.Adapters.Postgres
end
