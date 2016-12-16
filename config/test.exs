use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :liquio, Liquio.Endpoint,
	http: [port: 4001],
	server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :liquio, Liquio.Repo,
	adapter: Ecto.Adapters.Postgres,
	username: "postgres",
	password: "postgres",
	database: "liquio_test",
	hostname: "localhost",
	pool: Ecto.Adapters.SQL.Sandbox

config :liquio, default_trust_metric_url: "http://127.0.0.1:8080/dev_trust_metric.txt"
config :liquio, trust_metric_cache_time_seconds: 5 * 60
config :liquio, admin_identity_ids: 1..10
config :liquio, token_lifespan_minutes: 5
config :liquio, results_cache_seconds: 5
