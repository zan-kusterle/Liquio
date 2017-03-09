defmodule Liquio.Web.Endpoint do
	use Phoenix.Endpoint, otp_app: :liquio

	plug Plug.Static,
		at: "/",
		from: :liquio,
		gzip: true,
		only: ~w(css fonts images js icons robots.txt serviceworker.js)

	plug Plug.Static,
		at: "/",
		from: "/etc/letsencrypt/static",
		gzip: false,
		only: ~w(.well-known)

	# Code reloading can be explicitly enabled under the
	# :code_reloader configuration of your endpoint.
	if code_reloading? do
		socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
		plug Phoenix.LiveReloader
		plug Phoenix.CodeReloader
	end

	plug Liquio.Plugs.RedirectWww

	plug Plug.RequestId
	plug Plug.Logger

	plug Plug.Parsers,
		parsers: [:urlencoded, :multipart, :json],
		pass: ["*/*"],
		json_decoder: Poison

	plug Plug.MethodOverride
	plug Plug.Head

	plug Plug.Session,
		store: :cookie,
		key: "_liquio_key",
		signing_salt: "widKJvj0",
		max_age: 60 * 60 * 24 * 30

	plug CORSPlug, [origin: "*"]

	plug Liquio.Web.Router
end
