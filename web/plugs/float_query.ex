defmodule Democracy.Plugs.FloatQuery do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		value = Map.get(conn.params, query_name)
		if value == nil or String.length(value) == 0 do
			send_resp(conn, :bad_request, "Unable to parse float from param #{query_name}")
			|> halt
		else
			case Float.parse(value) do
				{value, _} ->
					assign(conn, assign_atom, value)
				:error ->
					send_resp(conn, :bad_request, "Unable to parse float from param #{query_name}")
					|> halt
			end
		end
	end
end