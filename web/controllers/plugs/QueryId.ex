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
			|> Phoenix.View.render(Democracy.ErrorView, "error.json", message: "Reference does not exist")
			|> halt
		end
	end
end