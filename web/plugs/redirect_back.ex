defmodule Democracy.Plugs.RedirectBack do
	import Plug.Conn

	def init(default), do: default

	def call(conn, _args) do
		redirect_back(conn)
	end

	def redirect_back(conn) do
  		case List.keyfind(conn.req_headers, "referer", 0) do
			{"referer", referer} ->
				url = URI.parse(referer)
				conn
				|> Phoenix.Controller.redirect to: url.path
			nil ->
				conn
				|> Phoenix.Controller.redirect to: "/"
		end
	end
end