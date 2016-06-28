defmodule Democracy.Plugs.QueryFlag do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		assign(conn, assign_atom,
			if Map.get(conn.params, query_name) do
				conn.params[query_name] == "true"
			else
				false
			end
		)
	end
end