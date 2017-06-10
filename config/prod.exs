use Mix.Config

config :liquio, Liquio.Web.Endpoint,
	http: [port: 4001],
	https: [
		port: 4000,
		keyfile: "/etc/letsencrypt/live/liqu.io/privkey.pem",
		certfile: "/etc/letsencrypt/live/liqu.io/cert.pem",
		cacertfile: "/etc/letsencrypt/live/liqu.io/chain.pem"
	],
	url: [host: "liqu.io", port: 443],
	cache_static_manifest: "priv/static/manifest.json",
	force_ssl: [hsts: true, subdomains: true]

config :logger, level: :info

config :liquio, default_trust_metric_url: "https://trust-metric.liqu.io"
config :liquio, trust_metric_cache_time_seconds: 30
config :liquio, results_cache_seconds: 10
config :liquio, enable_ipfs: true
config :liquio, infuse_link: "https://storage.googleapis.com/liquio/inject.js"
config :liquio, proxy_host: "https://proxy.liqu.io"

import_config "prod.secret.exs"
