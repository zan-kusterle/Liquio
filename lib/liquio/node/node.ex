defmodule Liquio.Node do
	alias Liquio.Node
	
	@enforce_keys [:path]
	defstruct [:path]

	def decode(key) do
		%Node{
			path: key |> String.trim(" ") |> String.split("/")
		}
	end
end
