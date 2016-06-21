defmodule Democracy.Plugs.QueryId do
	import Plug.Conn

	alias Democracy.Repo

	def init(default), do: default

	def call(conn, {assign_atom, schema, query_name}) do
		item = Repo.get(schema, conn.params[query_name])
		if item do
			assign(conn, assign_atom, item)
		else
			conn
			|> put_status(:not_found)
			|> Phoenix.Controller.render(Democracy.ErrorView, "error.json", message: "Invalid #{query_name} query parameter")
			|> halt
		end
	end

	def call(conn, {assign_atom, schema, query_name, is_item}) do
		item = Repo.get(schema, conn.params[query_name])
		# TODO: Also verify with is_item/2
		if item != nil do
			assign(conn, assign_atom, item)
		else
			conn
			|> put_status(:not_found)
			|> Phoenix.Controller.render(Democracy.ErrorView, "error.json", message: "Invalid #{query_name} query parameter")
			|> halt
		end
	end
end