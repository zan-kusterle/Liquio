defmodule Liquio.Node do
	alias Liquio.Node
	
	@enforce_keys [:path]
	defstruct [:path]

	def new(path) do
		%Node{path: path}
	end
	
	def decode(key) do
		key = String.replace(key, "://", ":")
		%Node{
			path: key |> String.trim(" ") |> String.split("/")
		}
	end
end
