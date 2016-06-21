defmodule Democracy.Plugs.EnsureCurrentIdentity do
	import Plug.Conn

	def init(_), do: nil

	def call(conn, _) do
		user = Guardian.Plug.current_resource(conn)
		if user != nil do
			assign conn, :user, user
		else
			conn
			|> send_resp(:unauthorized, "No current user")
			|> halt
		end
	end
end