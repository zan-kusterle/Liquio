defmodule Democracy.Plugs.Datetime do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		assign(conn, assign_atom,
			if Map.get(conn.params, query_name) do
				Ecto.DateTime.cast!(conn.params[query_name])
			else
				Ecto.DateTime.utc()
			end
		)
	end
end