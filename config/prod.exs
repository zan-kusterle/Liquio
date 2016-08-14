use Mix.Config

config :liquio, Liquio.Endpoint,
  http: [port: 4001],
  https: [
  	port: 4000,
    keyfile: "/etc/letsencrypt/live/liqu.io/privkey.pem",
    certfile: "/etc/letsencrypt/live/liqu.io/cert.pem",
    cacertfile: "/etc/letsencrypt/live/liqu.io/chain.pem"
  ],
  url: [host: "liqu.io", port: 443],
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  force_ssl: [hsts: true, subdomains: true]

config :liquio, default_trust_metric_url: "https://trust-metric.liqu.io"
config :liquio, trust_metric_cache_time_seconds: 5 * 60

config :logger, level: :info

import_config "prod.secret.exs"
