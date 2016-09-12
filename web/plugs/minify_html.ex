defmodule Liquio.Plugs.MinifyHtml do
	@behaviour Plug

	import Plug.Conn

	def init(opts), do: opts

	def call(conn, _opts) do
		register_before_send(conn, fn(conn) ->
			[content_type | _tail] = get_resp_header(conn, "content-type")
			if String.contains?(content_type, "text/html") do
				html = conn.resp_body
				|> to_string
				|> String.replace("\t", "")
				|> String.replace("\n", "")
				|> String.replace("\r", "\n")
				|> String.replace("<!DOCTYPE html>", "<!DOCTYPE html>\n")
				resp(conn, conn.status, html)
			else
				conn
			end
		end)
	end
end