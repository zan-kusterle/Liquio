defmodule Liquio.Plugs.RedirectWww do
	import Plug.Conn

	def init(opts), do: opts

	def call(conn, opts) do
		if conn.host |> String.starts_with?("www.") do
			port = if conn.port != 80 and conn.port != 443 do ":#{conn.port}" else "" end
			query = if String.length(Map.get(conn, :query_string, "")) > 0 do "?#{conn.query_string}" else "" end
			url = to_string(conn.scheme) <> "://" <> String.trim_leading(conn.host, "www.") <> port <> conn.request_path <> query
			conn
			|> Phoenix.Controller.redirect(external: url)
			|> halt
		else
			conn
		end
	end
end