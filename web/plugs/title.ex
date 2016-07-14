defmodule Democracy.Plugs.Title do

	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		if value = Map.get(conn.params, query_name) do
			value = value |> String.trim
			%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => value})}
		else
			conn
			|> put_status(:not_found)
			|> Phoenix.Controller.render(Democracy.ErrorView, "error.json", message: "Invalid #{query_name} query parameter")
			|> halt
		end
	end
end