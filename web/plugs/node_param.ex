defmodule Liquio.Plugs.NodeParam do
	def handle(_conn, value, opts) do		
		Liquio.Node.decode value
	end
end