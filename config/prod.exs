use Mix.Config

config :liquio, Liquio.Endpoint,
  http: [port: 4001],
  https: [
  	port: 4000,
    keyfile: "/etc/letsencrypt/live/liqu.io/privkey.pem",
    certfile: "/etc/letsencrypt/live/liqu.io/cert.pem"
  ],
  url: [host: "liqu.io", port: 443],
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  force_ssl: [hsts: true]

config :liquio, default_trust_metric_url: "http://127.0.0.1:8080/dev_trust_metric.txt"
config :liquio, trust_metric_cache_time_seconds: 5 * 60

config :logger, level: :info

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :liquio, Liquio.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :liquio, Liquio.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :liquio, Liquio.Endpoint, server: true
#
# You will also need to set the application root to `.` in order
# for the new static assets to be served after a hot upgrade:
#
#     config :liquio, Liquio.Endpoint, root: "."

# Finally import the config/prod.secret.exs
# which should be versioned separately.
import_config "prod.secret.exs"
