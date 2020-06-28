# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :proj42,
  ecto_repos: [Proj42.Repo]

# Configures the endpoint
config :proj42, Proj42Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pe/mMgsvPbfTqQEGrN1pLcxWJ5zIRX/dm+OTcS7fVqk3Z+6SULvhM7ad/y72byJb",
  render_errors: [view: Proj42Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Proj42.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
