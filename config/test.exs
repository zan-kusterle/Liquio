use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :liquio, LiquioWeb.Endpoint,
	http: [port: 4000]

# Print only warnings and errors during test
config :logger, level: :warn

config :liquio, results_cache_seconds: nil
config :liquio, messages_url: "http://localhost:5000/messages"
