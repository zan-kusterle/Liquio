defmodule Democracy.Plugs.IdentityParam do
	def handle(conn, value, opts) do
		if value == "me" do
			identity = Guardian.Plug.current_resource(conn)
			if identity == nil do
				{:error, :not_found, opts[:message] || "Not found"}
			else
				{:ok, identity}
			end
		else
			Democracy.Plugs.ItemParam.handle(conn, value, opts ++ [schema: Democracy.Identity])
		end
	end
end