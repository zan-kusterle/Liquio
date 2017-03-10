# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :liquio, Liquio.Web.Endpoint,
	url: [host: "localhost"],
	root: Path.dirname(__DIR__),
	secret_key_base: "OXjxWdx9pts7IKCZsEjYzi17TxtdnspYpOWNT9xEkjq1owWJCGF/Rn6C1LzKNkSZ",
	render_errors: [view: Liquio.Web.ErrorView, accepts: ~w(html json)],
	pubsub: [
		name: Liquio.PubSub,
		adapter: Phoenix.PubSub.PG2
	]

config :liquio, ecto_repos: [Liquio.Repo]

# Configures Elixir's Logger
config :logger, :console,
	format: "$time $metadata[$level] $message\n",
	metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
	migration: true,
	binary_id: false

config :guardian, Guardian,
	allowed_algos: ["HS512"], # optional
	verify_module: Guardian.JWT,  # optional
	issuer: "Liquio",
	ttl: { 30, :days },
	verify_issuer: true, # optional
	secret_key: "nCtmk9gVyGfAgab9KMCkQdjXdgGUwTB2SO5piuvoqDoK4t0MEmbpHHzHsiw5GIYR",
	serializer: Liquio.GuardianSerializer