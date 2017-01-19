defmodule Liquio.Plugs.NodeParam do
	def handle(_conn, value, opts) do		
		{:ok, Liquio.Node.decode value}
	end
end