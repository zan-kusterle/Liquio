use Mix.Config

config :liquio, LiquioWeb.Endpoint,
	http: [port: 4000],
	debug_errors: false,
	code_reloader: true,
	check_origin: false,
	watchers: [
		node: ["node_modules/webpack/bin/webpack.js", "--watch-stdin", cd: Path.expand("../assets", __DIR__)],
		node: ["node_modules/webpack/bin/webpack.js", "--watch-stdin", cd: Path.expand("../promo", __DIR__)]
	]

# Watch static and templates for browser reloading.
config :liquio, LiquioWeb.Endpoint,
	live_reload: [
		patterns: [
			~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
			~r{priv/gettext/.*(po)$},
			~r{lib/liquio/web/views/.*(ex)$},
			~r{lib/liquio/web/templates/.*(eex)$}
		]
	]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

config :liquio, results_cache_seconds: nil
config :liquio, messages_url: "http://localhost:5000/messages"

import_config "dev.secret.exs"