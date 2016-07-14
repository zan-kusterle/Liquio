defmodule Democracy.Plugs.QueryIdentityIdFallbackCurrent do
	import Plug.Conn

	alias Democracy.Repo
	alias Democracy.Identity

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		query_id = conn.params[query_name]
		
		user = if query_id == "me" do
			Guardian.Plug.current_resource(conn)
		else
			user = Repo.get(Identity, query_id)
		end

		if user do
			%{conn | params: conn.params |> Map.merge(conn.query_params) |> Map.merge(%{assign_atom => user})}
		else
			send_resp(conn, :not_found, "Identity does not exist")
			|> halt
		end
	end
end