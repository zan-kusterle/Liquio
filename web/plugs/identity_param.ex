defmodule Liquio.Plugs.IdentityParam do
	def handle(conn, value, opts) do
		if value == "me" do
			identity = Guardian.Plug.current_resource(conn)
			if identity == nil do
				{:error, :not_found, opts[:message] || "Not found"}
			else
				{:ok, identity}
			end
		else
			Liquio.Plugs.ItemParam.handle(conn, value, opts ++ [schema: Liquio.Identity])
		end
	end
end