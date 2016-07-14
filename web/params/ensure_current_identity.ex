defmodule Democracy.Plugs.EnsureCurrentIdentity do
	import Plug.Conn

	def init(_), do: nil

	def call(conn, _) do
		user = Guardian.Plug.current_resource(conn)
		if user != nil do
			%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{:user => user})}
		else
			if :browser in conn.private.phoenix_pipelines do
				conn
				|> Phoenix.Controller.redirect to: "/login"
			else
				conn
				|> send_resp(:unauthorized, "No current user")
				|> halt
			end
		end
	end
end