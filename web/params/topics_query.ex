defmodule Democracy.Plugs.TopicsQuery do
	import Plug.Conn

	use Democracy.Web, :controller

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		topics = Map.get(conn.params, query_name, "") |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.filter(& String.length(&1) > 0)
		%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => topics})}
	end
end