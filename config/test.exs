use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :democracy, Democracy.Endpoint,
	http: [port: 4001],
	server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :democracy, Democracy.Repo,
	adapter: Ecto.Adapters.Postgres,
	username: "postgres",
	password: "postgres",
	database: "democracy_test",
	hostname: "localhost",
	pool: Ecto.Adapters.SQL.Sandbox

config :democracy, default_trust_metric_url: "http://127.0.0.1:8080/dev_trust_metric.txt"
config :democracy, trust_metric_cache_time_seconds: 5 * 60