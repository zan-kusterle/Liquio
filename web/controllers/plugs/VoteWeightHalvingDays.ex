defmodule Democracy.Plugs.VoteWeightHalvingDays do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		assign(conn, assign_atom,
			if Map.get(conn.params, query_name) do
				{value, _} = Integer.parse(conn.params[query_name])
				value
			else
				nil
			end
		)
	end
end