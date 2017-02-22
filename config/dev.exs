use Mix.Config

config :liquio, Liquio.Endpoint,
	http: [port: 4000],
	debug_errors: false,
	code_reloader: true,
	check_origin: false,
	watchers: [node: ["node_modules/webpack/bin/webpack.js", "--watch-stdin"]]

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

config :liquio, default_trust_metric_url: "http://127.0.0.1:8080/dev_trust_metric.html"
config :liquio, trust_metric_cache_time_seconds: 5
config :liquio, token_lifespan_minutes: 60
config :liquio, results_cache_seconds: 30

import_config "dev.secret.exs"