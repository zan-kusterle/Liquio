use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :liquio, Liquio.Endpoint,
	http: [port: 4000],
	debug_errors: true,
	code_reloader: true,
	check_origin: false,
	watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin", cd: Path.expand("../", __DIR__)]]

# Watch static and templates for browser reloading.
config :liquio, Liquio.Endpoint,
	live_reload: [
		patterns: [
			~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
			~r{priv/gettext/.*(po)$},
			~r{web/views/.*(ex)$},
			~r{web/templates/.*(eex)$}
		]
	]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :liquio, Liquio.Repo,
	adapter: Ecto.Adapters.Postgres,
	username: "postgres",
	password: "postgres",
	database: "liquio_dev",
	hostname: "localhost",
	pool_size: 10

config :liquio, default_trust_metric_url: "http://127.0.0.1:8080/dev_trust_metric.txt"
config :liquio, trust_metric_cache_time_seconds: 5
config :liquio, admin_identity_ids: 1..10