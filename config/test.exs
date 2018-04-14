use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :liquio, Liquio.Web.Endpoint,
	http: [port: 4000]

# Print only warnings and errors during test
config :logger, level: :warn

config :liquio, default_trust_metric_url: "http://127.0.0.1:8080/dev_trust_metric.txt"
config :liquio, trust_metric_cache_time_seconds: 5 * 60
config :liquio, results_cache_seconds: 5
config :liquio, enable_ipfs: false
config :liquio, infuse_link: "http://localhost:8080/inject.js"
config :liquio, proxy_host: "http://proxy-liqu.io"
