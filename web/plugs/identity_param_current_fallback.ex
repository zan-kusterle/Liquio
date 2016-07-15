defmodule Democracy.Plugs.IdentityParamCurrentFallback do
	def handle(conn, opts) do
		item = Democracy.Repo.get(Identity, conn.params[opts[:name]])
		if item != nil do
			{:ok, item}
		else
			identity = Guardian.Plug.current_resource(conn)
			if identity == nil do
				{:error, :not_found, opts[:message] || "Not found"}
			else
				{:ok, identity}
			end
		end
	end
end