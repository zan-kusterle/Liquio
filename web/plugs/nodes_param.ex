defmodule Liquio.Plugs.NodesParam do
	def handle(_conn, value, opts) do		
		nodes = Liquio.Node.decode_many value
		if Enum.empty?(nodes) do {:ok, nil} else {:ok, nodes} end
	end
end