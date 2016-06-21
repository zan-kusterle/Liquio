defmodule Democracy.Plugs.QueryIdentityIdEnsureCurrent do
	import Plug.Conn

	def init(default), do: default

	def call(conn, {assign_atom, query_name}) do
		user = Guardian.Plug.current_resource(conn)
		query_id = conn.params[query_name]
		if query_id == "me" do
			query_id = user.id
		end
		if user != nil and to_string(user.id) == to_string(query_id) do
			assign conn, assign_atom, user
		else
			send_resp(conn, :unauthorized, "Can only create delegations for yourself")
			|> halt
		end
	end
end