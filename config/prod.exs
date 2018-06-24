use Mix.Config

config :liquio, LiquioWeb.Endpoint,
	http: [port: 4000],
	url: [host: "liqu.io", port: 443],
	cache_static_manifest: "priv/static/cache_manifest.json",
	server: true

config :logger, level: :info

config :liquio, results_cache_seconds: nil
config :liquio, messages_url: "https://sign.liqu.io/messages"

# Used to be in prod.secret.exs
config :liquio, Liquio.Repo,
	adapter: Ecto.Adapters.Postgres,
	username: "postgres",
	password: "postgres",
	database: "postgres",
	hostname: "localhost",
	pool_size: 10

import_config "prod.secret.exs"
