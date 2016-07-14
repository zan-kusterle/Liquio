defmodule Democracy.Plugs.QueryFlag do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		value = if Map.get(conn.params, query_name) do
			conn.params[query_name] == "true"
		else
			false
		end
		%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => value})}
	end
end