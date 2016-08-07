defmodule Liquio.Plugs.CurrentUser do
	def handle(conn, value, opts) do
		identity = Guardian.Plug.current_resource(conn)
		if identity == nil do
			if opts[:require] do
				{:error, :unauthorized, "No current user"}
			else
				{:ok, nil}
			end
		else
			{:ok, identity}
		end
	end
end