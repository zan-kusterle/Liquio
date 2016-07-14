defmodule Democracy.Plugs.CurrentUser do
	def handle(conn, opts) do
		identity = Guardian.Plug.current_resource(conn)
		if identity == nil do
			{:error, :unauthorized, "No current user"}
		else
			{:ok, identity}
		end
	end
end