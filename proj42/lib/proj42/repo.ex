defmodule Proj42.Repo do
  use Ecto.Repo,
    otp_app: :proj42,
    adapter: Ecto.Adapters.Postgres  
end
